// written in the D programming language
/*
*   This file is part of FostomEngine.
*   
*   FostomEngine is free software: you can redistribute it and/or modify
*   it under the terms of the GNU General Public License as published by
*   the Free Software Foundation, either version 3 of the License, or
*   (at your option) any later version.
*   
*   FostomEngine is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*   
*   You should have received a copy of the GNU General Public License
*   along with FostomEngine.  If not, see <http://www.gnu.org/licenses/>.
*/
/**
*   Copyright: © 2012-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*	KD-дерево позволяет эффективно представить в памяти воксельную модель и быстро отрисовать ее.
*/
module util.terrain.kdtree;

import std.traits;
import std.math;
import std.conv;

import std.stdio;
import std.exception;
import std.bitmanip;
import std.algorithm;
import std.system;
import std.zlib;
import std.stream;

import util.log;
import util.vector;
import util.list;
import util.linkedarray;

void d(T...)(T args)
{
	import std.stdio;
	import std.conv;
	
	debug writeln(text(args));
	//getchar();
}

void db(ref BitArray arr)
{
	import std.stdio;
	foreach(bit; arr)
		write(cast(uint)bit);
	writeln();	
}

/**
*	Исключение кидается, когда обнаруживается ошибка в формате бинарного файла 
*	kd-дерева. Например: версия формата не совпадает с заданной.
*/
class KdTreeFormatException : Exception
{
	this(T...)(ulong pos, T args)
	{
		super(text(args));
		errorPosition = pos;
	}
	
	ulong errorPosition;
}

/**
*	Ошибка загрузки дерева из файла.
*/
class KdTreeLoadException : Exception
{
	this(T...)(T args)
	{
		super(text(args));
	}
}

/// Находится в начале файла с деревом
private enum FILE_FORMAT_MAGIC = "KDv2";

/**
*	Стандартное кд-дерево для представления больших моделей. Используется бинарное разбиение,
*	снижающее точность, но очень сильно ужимающее размер модели.
*/
alias KdTree!(uint, 0) StdKdTree;

/**
*	Дерево, в котором положение плоскости кодируется 4 битами.
*/
alias KdTree!(uint, 4) KdTree4;

/**
*	Дерево, в котором полжение плоскости кодируется 8 битами.
*/
alias KdTree!(uint, 8) KdTree8;

/**
*	Дерево, в котором положение плоскости кодируется 16 битами.
*	Большая точность уже не дает никаких плюсов, только разбухает
*	размер дерева, поэтому нужно юзать наименьшее кол-во битов,
*	когда это возможно.
*/
alias KdTree!(uint, 16) KdTree16;

/**
*	Kd-дерево для компактного представления воксельных моделей. Дерево в каждом узле
*	делит пространство на два с помощью секущей плосксоти, параллельной одной из 
*	координатной плоскости. Направление плоскостей чередуется с каждым уровнем 
*	дерева: OXY->OYZ->OXZ->OXY->...  
*
*	Params:
*			MaterialIdType =	тип id материала, который будет использоваться
*				внутри цвето-материальной таблицы модели. 
*
*			plainPrecision =	количество битов, задающих возможные
*				положения разделяющей плоскости внутри локального узла.
*				По умолчанию плоскость делит пополам пространство и 
*				используется 0 битов. Менять только для моделей с повышенными
*				требованиями на точность разбиения.
*
*			chunkSize =		модель может занимать огромные участки памяти, поэтому
*				для ее хранения испольуются связанные массивы. Число указывает
*				размер одного массива в байтах. По умолчанию чанк занимает 10 мб.
*
*	Note: Все значения в дереве хранятся в little-endian, и динамически конвертятся
*		при предаче дерева от машины к машине.
*/
class KdTree(MaterialIdType, ushort plainPrecision = 0, ulong chunkSize = 256)
{
	static assert(isIntegral!MaterialIdType, "KdTree supports only integral types for MaterialIdType, not the "~MaterialIdType.stringof);
	
	this()
	{
		mMem = new ModelMemory!480;
	}
	
	this(Stream file)
	{
		this();
		loadFromStream(file);
	}
	
	/**
	*	Загрузка данных из массива data. IndexType определяет тип индекса, хранимый
	*	в массиве, на запись в таблице цвето-материалов table. 
	*/
	void load(IndexType)(IndexType[][][] data, ColorInfo[] table)
	{
		// Получаем размеры модели
		void getModelSize()
		{
			auto x = data.length;
			if(x == 0) throw new KdTreeLoadException("Cannot load model: x size is 0!");
			
			auto y = data[0].length;
			if(y == 0) throw new KdTreeLoadException("Cannot load model: y size is 0!");
			
			auto z = data[0][0].length;
			if(z == 0) throw new KdTreeLoadException("Cannot load model: z size is 0!");
			
			mSize =  vec3ul(x,y,z);			
		}
		
		void dispatchDirection(PLAIN_DIR dir, void delegate() xdir, void delegate() ydir, void delegate() zdir)
		{
			final switch(dir)
			{
				case PLAIN_DIR.X_AXIS:
				{
					xdir();
					break;
				}
				case PLAIN_DIR.Y_AXIS:
				{
					ydir();
					break;
				}
				case PLAIN_DIR.Z_AXIS:
				{
					zdir();
					break;
				}
			}

		}

		//=========================================
		// Сохраняем таблицу цветов
		mColorTable = table;
		getModelSize();
		
		// Инициализируем стек
		auto dir = PLAIN_DIR.Z_AXIS;
		auto stack = new List!(VolumeInfo!IndexType)(VolumeInfo!IndexType(0,0,0,cast(size_t)mSize.x, cast(size_t)mSize.y, cast(size_t)mSize.z));
		ulong levelSize = 0;
		ulong nextLevel = 1;

		// Обрабатываем все подпространства
		while(stack.length > 0)
		{
			if(levelSize == 0) 
			{
				// При переходе на новый уровень дерева выравниваем размер данных по size_t и добавляем
				// в мету смещение.
				auto l = mMem.finalize();
				mMem.nextLevel(l);

				levelSize = nextLevel;
				nextLevel = 0;
				
				dir = nextDir(dir);
				d("Next dir is: ", dir);
			}
			
			if(stack.front.node)
			{
				// Считаем разделяющую плоскость
				ulong codedPlace;
				size_t plain = choosePlain!IndexType(data, stack.front, dir, codedPlace);
				
				// Считаем левое и правое подпространства
				auto left = stack.front;
				auto right = stack.front;
				
				void xdir()
				{
					left.v2.x = plain;
					right.v1.x = plain;						
				}
				void ydir()
				{
					left.v2.y = plain;
					right.v1.y = plain;							
				}
				void zdir()
				{
					left.v2.z = plain;
					right.v1.z = plain;						
				}
				dispatchDirection(dir, &xdir, &ydir, &zdir);
				

				// Проверяем на однородность
				IndexType fillValLeft, fillValRight;
				if(isOneValFilled(data, fillValLeft, left))
				{
					left.node = false;
					left.val = fillValLeft;
				} else
				{
					left.node = true;
				}
	
				stack.pushBack(left);
				nextLevel+=1;	
						
				if(isOneValFilled(data, fillValRight, right))
				{
					right.node = false;
					right.val = fillValRight;
				} else
				{
					right.node = true;
				}
					
				stack.pushBack(right);
				nextLevel+=1;			
				
				// Запись узла в память
				mMem.writeNode(codedPlace,left.node,right.node);
			} else
			{
				// Запись листа
				mMem.writeLeaf(stack.front.val);
			}	
			
			// Подготовка к следующей итерации
			levelSize-=1;
			stack.popFront();
		}
		
		mMem.finalize();
	}
	
	/**
	*	Получение размера нода в битах!
	*/
	size_t nodeSize() @property
	{
		return plainPrecision+2;
	} 
	
	/**
	*	Получение размера полного листа в битах! 
	*/
	size_t leafFullSize() @property
	{
		return colorTableBits+1; 
	}
	
	/**
	*	Получение размера удаленного листа в битах!
	*/
	size_t leafEmptySize() @property
	{
		return 1;
	}
	
	/**
	*	Структура, которая хранит информацию о цвете и материале.
	*	Воксели ссылаются на таблицу цветов, в которой находятся
	*	эти структуры.
	*/
	struct ColorInfo
	{
		vec4 color;
		MaterialIdType matId;
		
		/**
		*	Записывает цвет внутрь потока. 
		*/
		private void writeTo(ref Stream stream)
		{
			stream.writeExact(color.m.ptr, color.StorageType.sizeof*color.dimentions);
			stream.write(matId);
		}
		
		/**
		*	Читаем из потока
		*/
		private void readFrom(ref Stream stream)
		{
			stream.readExact(color.m.ptr, color.StorageType.sizeof*color.dimentions);
			stream.read(matId);
		}
	}	
	
	/**
	*	Задает направление разбивающей плоскости.
	*/
	enum PLAIN_DIR
	{
		X_AXIS,
		Y_AXIS,
		Z_AXIS
	}
	
	/**
	*	Описывает положение листа дерева и его материал.
	*/
	struct LeafInfo
	{
		size_t colorIndex;
		vec3 v1;
		vec3 v2;
	}
	
	/**
	*	Получение массива всех листьев дерева, которые не пусты.
	*	
	*	Warning: Используется только для дебага.
	*/
	LeafInfo[] leafs() @property
	{
		/**
		*	Элемент стека для алгоритма
		*/
		struct MapElement
		{
			vec3ul v1, v2;
		}
		
		/**
		*	Выдирает из данных битов число и возвращает size_t.
		*/
		size_t getNumber(ref BitArray bits, size_t x, size_t y)
		{
			BitArray sbits;
			sbits.length(y-x);
			
			for(size_t i = 0; i<y-x; ++i)
				sbits[i] = bits[x+i];

			ubyte[] buff = cast(ubyte[])cast(size_t[])(sbits);

			// Конвертим в нужное значение	
			return peek!(size_t, Endian.littleEndian)(buff);
		}
		
		/**
		*	Получает из родительского пространства левое относительно плоскости plain и ее направления dir.
		*	Значение plain можно представить как "сколько минимальных отрезков может поместиться между
		*	началом отсчета и плоскостью".
		*/
		MapElement getLeftSubVolume(ref MapElement parent, ulong plain, PLAIN_DIR dir)
		{
			MapElement ret = parent;
			if(plain == 0) return ret;
			
			static if(plainPrecision > 0)
			{
				ulong maxPositions = pow(2, plainPrecision);
			} else
			{
				ulong maxPositions = 2;
				plain = 1;
			}
			
			final switch(dir)
			{
				case PLAIN_DIR.X_AXIS:
				{
					double inc = cast(double)(ret.v2.x-ret.v1.x)/maxPositions;
					ret.v2.x = cast(ulong)(ret.v1.x+plain*inc);
					break;
				}
				case PLAIN_DIR.Y_AXIS:
				{
					double inc = cast(double)(ret.v2.y-ret.v1.y)/maxPositions;
					ret.v2.y = cast(ulong)(ret.v1.y+plain*inc);
					break;
				}
				case PLAIN_DIR.Z_AXIS:
				{
					double inc = cast(double)(ret.v2.z-ret.v1.z)/maxPositions;
					ret.v2.z = cast(ulong)(ret.v1.z+plain*inc);
					break;
				}
			}
			return ret;
		}
		
		/**
		*	Получает из родительского пространства правое относительно плоскости plain и ее направления dir.
		*	Значение plain можно представить как "сколько минимальных отрезков может поместиться между
		*	началом отсчета и плоскостью".
		*/		
		MapElement getRightSubVolume(ref MapElement parent, ulong plain, PLAIN_DIR dir)
		{
			MapElement ret = parent;
			if(plain == 0) return ret;
			
			static if(plainPrecision > 0)
			{
				ulong maxPositions = pow(2, plainPrecision);
			} else
			{
				ulong maxPositions = 2;
				plain = 1;
			}
			
			final switch(dir)
			{
				case PLAIN_DIR.X_AXIS:
				{
					double inc = cast(double)(ret.v2.x-ret.v1.x)/maxPositions;
					ret.v1.x = cast(ulong)(ret.v1.x+plain*inc);
					break;
				}
				case PLAIN_DIR.Y_AXIS:
				{
					double inc = cast(double)(ret.v2.y-ret.v1.y)/maxPositions;
					ret.v1.y = cast(ulong)(ret.v1.y+plain*inc);
					break;
				}
				case PLAIN_DIR.Z_AXIS:
				{
					double inc = cast(double)(ret.v2.z-ret.v1.z)/maxPositions;
					ret.v1.z = cast(ulong)(ret.v1.z+plain*inc);
					break;
				}
			}
			return ret;
		}
				
		// Подготовка стека, карт следующий и текущих уровней		
		auto ret = new LeafInfo[0];
		auto map = [true];
		bool[] mapNext;
		size_t mapIndex;
		size_t mapNextIndex;
		
		auto volumeMap = [MapElement(vec3ul(0,0,0), vec3ul(mSize.x,mSize.y,mSize.z))];
		MapElement[] volumeMapNext;
		size_t volumeMapIndex;
		size_t volumeMapNextIndex;
		
		PLAIN_DIR dir = PLAIN_DIR.X_AXIS;
		
		// Считываем по уровню в дереве
		foreach(level; mMem) 
		{
			mapIndex = 0;
			volumeMapIndex = 0;
			
			// Колво элементов на следующем уровне зависит от предыдущего
			auto size = cast(size_t)count!"a == true"(map);
			mapNext = new bool[2*size];
			volumeMapNext = new MapElement[2*size];
			
			mapNextIndex = 0;
			volumeMapNextIndex = 0;
			
			// Читаем, пока не закончилась карта или уровень
			for(size_t i = 0; i<level.length && mapIndex<map.length; mapIndex++)
			{
				if(map[mapIndex]) // читаем узел
				{
					// получаем плоскость
					static if(plainPrecision > 0)
					{
						ulong plain = getNumber(level, i, i+plainPrecision);
						i+= plainPrecision;
					}
					else
						ulong plain = 1; // doesn't care what
					
					// считаем новые подпространства
					auto pv = volumeMap[mapIndex];
					volumeMapNext[volumeMapNextIndex++] = 
						getLeftSubVolume(pv, plain, dir);
					volumeMapNext[volumeMapNextIndex++] = 
						getRightSubVolume(pv, plain, dir);	
					
					// получаем инфу о поднодах
					mapNext[mapNextIndex++] = level[i++];
					mapNext[mapNextIndex++] = level[i++];
				} else // читаем лист
				{

					if(!level[i++]) // Пустые листья нам не нужны
					{
						// Вытаскиваем индекс цвета из таблицы цвето-материалов
						ulong index = 0;
						if(colorTableBits > 0)
						{
							index = getNumber(level, i, i+colorTableBits);
							i+= colorTableBits;
						}
						
						// Конвертим внутреннее представление позиции в относительные координаты
						auto pv = volumeMap[mapIndex];
						auto v1 = vec3(cast(float)pv.v1.x/mSize.x, cast(float)pv.v1.y/mSize.y, cast(float)pv.v1.z/mSize.z);
						auto v2 = vec3(cast(float)pv.v2.x/mSize.x, cast(float)pv.v2.y/mSize.y, cast(float)pv.v2.z/mSize.z);
						// Добавляем в выхлоп лист
						ret ~= LeafInfo(cast(size_t)index, v1, v2);
					}
				}
			}	
			
			// Готовимся к следующему уровню
			volumeMap = volumeMapNext;
			map = mapNext;
			dir = nextDir(dir);
		}
		return ret;
	}
	
	/**
	*	Габаритные размеры модели в вокселях.
	*/
	vec3ul size() @property
	{
		return mSize;
	}
	
	/**
	*	Загрузка kd-дерева из потока.
	*/
	void loadFromStream(Stream stream)
	{
		ulong colorTable, metaData, data;
		
		stream.seek(0, SeekPos.Set);
		
		readHeader(stream, colorTable, metaData, data);
		stream.seek(colorTable, SeekPos.Set);
		readColorTable(stream);
		stream.seek(metaData, SeekPos.Set);
		mMem.readMeta(stream);
		stream.seek(data, SeekPos.Set);
		mMem.readData(stream);
	}
	
	/**
	*	Сохранение kd-дерева в поток.
	*/
	Stream saveToStream()
	{
		auto stream = new MemoryStream;
		// Header мы запишем позже
		auto dummyBuff = new ubyte[cast(size_t)headerSize];
		stream.write(dummyBuff);
		stream.seek(0, SeekPos.End);
		 
		ulong colorTable = writeColorTable(cast(Stream)stream);
		ulong metaData = mMem.writeMeta(cast(Stream)stream);
		ulong data = mMem.writeData(cast(Stream)stream);
		
		// Возвращаемся и записываем хедер
		stream.seek(0, SeekPos.Set);
		writeHeader(cast(Stream)stream, colorTable, metaData, data);
		  
		return stream;
	}
//=====================================================================================================================================
//	Private members
//=====================================================================================================================================				
	private
	{
		/**
		*	Записывает заголовок файла. Берет смещения соответствущих структур в файле.
		*/
		void writeHeader(Stream stream, ulong colorTable, ulong metaData, ulong data)
		{
			// magic number
			stream.writeString(FILE_FORMAT_MAGIC);
			// размеры модели
			stream.writeExact(mSize.m.ptr, mSize.StorageType.sizeof*mSize.dimentions);
			
			stream.write(colorTable);
			stream.write(metaData);
			stream.write(data);
		}
		
		/**
		*	Получаем размер хедера файла, чтобы его можно было записать позже.
		*/
		ulong headerSize() @property
		{
			return FILE_FORMAT_MAGIC.length*char.sizeof+mSize.StorageType.sizeof*mSize.dimentions+3*ulong.sizeof;
		}
		
		/**
		*	Читаем заголовок файла и обрабатываем ошибки. Возвращает смещения основных структур в файле.
		*/
		void readHeader(Stream stream, out ulong colorTable, out ulong metaData, out ulong data)
		{
			// magic number
			string magic = stream.readString(FILE_FORMAT_MAGIC.length).idup;
			if(magic != FILE_FORMAT_MAGIC)
				throw new KdTreeFormatException(0, "File is not kdtree or format version doesn't supported!");
				
			// читаем размеры модели
			stream.readExact(mSize.m.ptr, mSize.StorageType.sizeof*mSize.dimentions);
			
			stream.read(colorTable);
			stream.read(metaData);
			stream.read(data);
		}
		
		/**
		*	Записывает таблицу цветов в поток. Возвращает смещение в потоке.
		*/
		ulong writeColorTable(Stream stream)
		{
			ulong ret = stream.position;
			stream.write(cast(ulong)mColorTable.length);
			foreach(color; mColorTable)
				color.writeTo(stream);
			return ret;	
		}
		
		/**
		*	Читаем таблицу цветов.
		*/
		void readColorTable(Stream stream)
		{
			scope(failure)
				throw new KdTreeFormatException(stream.position, "Reading color table failed!");
				
			ulong colors;
			stream.read(colors);
			mColorTable = new ColorInfo[cast(size_t)colors];
			foreach(ref color; mColorTable) 
			{
				color.readFrom(stream);
			}
		}
		
		/**
		*	Получает количество битов, необходимое
		*	для записи индекса на цвет в таблице
		*	цвето-материалов.
		*/
		size_t colorTableBits() @property
		{
			return cast(size_t)ceil(log2(cast(real)mColorTable.length));
		}
		
		/**
		*	Получение следующего направления секущей плоскости.
		*	Выбирается по закольцованной цепочке: X->Y->Z.
		*/
		final PLAIN_DIR nextDir(PLAIN_DIR dir) pure nothrow
		{
			final switch(dir)
			{
				case PLAIN_DIR.X_AXIS:
					return PLAIN_DIR.Y_AXIS;
					break;
				case PLAIN_DIR.Y_AXIS:
					return PLAIN_DIR.Z_AXIS;
					break;
				case PLAIN_DIR.Z_AXIS:
					return PLAIN_DIR.X_AXIS;
					break;
			}
		}
		
		/**
		*	Выбирает оптимальную плоскость разбиения с учетом точности
		*	разбиения (возможных положений) и стоимости отрисовки.
		*/
		size_t choosePlain(IndexType)(IndexType[][][] data, VolumeInfo!IndexType space, in PLAIN_DIR dir, out ulong codedPlace)
		{
			// бинарное разбиения, 0 бит
			size_t chooseSimple()
			{
				codedPlace = 1;
				final switch(dir)
				{
					case PLAIN_DIR.X_AXIS:
						return (space.v1.x + space.v2.x)/2;
						break;
					case PLAIN_DIR.Y_AXIS:
						return (space.v1.y + space.v2.y)/2;
						break;
					case PLAIN_DIR.Z_AXIS:
						return (space.v1.z + space.v2.z)/2;
						break;
				}				
			}
			
			/*
			*	Разбиение по эвреистике SAH. Минимизируется функция:
			*	SAH(x) = CostEmpty + SurfaceArea(Left)*N(Left) + SurfaceArea(Right)*N(Right)
			*/
			size_t chooseSAH(ulong maxPositions)
			{
				enum CostEmpty = 0;
				
				// Подсчитывание количества значений в подмассиве
				ulong countAtVolume(ref VolumeInfo!IndexType space) nothrow
				{
					ulong ret = 0;
					for(size_t i=space.v1.x; i<space.v2.x; i++)
						for(size_t j=space.v1.y; j<space.v2.y; j++)
							for(size_t k=space.v1.z; k<space.v2.z; k++)
								if(data[i][j][k] != 0)
									++ret;
					return ret;
				}
		
				size_t ret;
				double cost = double.max;
				auto left = space;
				auto right = space;
				
				//d(maxPositions);
				final switch(dir)
				{
					case PLAIN_DIR.X_AXIS:
					{
						size_t inc = cast(size_t)((space.v2.x-space.v1.x)/maxPositions);
						if(inc == 0)
							inc = 1;
							
						for(size_t k = space.v1.x; k<space.v2.x; k+= inc)
						{
							left.v2.x = k;
							right.v1.x = k;
							auto sah = CostEmpty + left.volume*countAtVolume(left) + right.volume*countAtVolume(right);
							if( sah < cost )
							{
								cost = sah;
								ret = k;
							}
						}
						
						codedPlace = cast(ulong)(maxPositions*(ret-space.v1.x)/cast(double)(space.v2.x-space.v1.x));
						break;
					}
					case PLAIN_DIR.Y_AXIS:
					{
						size_t inc = cast(size_t)((space.v2.y-space.v1.y)/maxPositions);
						if(inc == 0)
							inc = 1;
							
						for(size_t k = space.v1.y; k<space.v2.y; k+= inc)
						{
							left.v2.y = k;
							right.v1.y = k;
							auto sah = CostEmpty + left.volume*countAtVolume(left) + right.volume*countAtVolume(right);
							if( sah < cost )
							{
								cost = sah;
								ret = k;
							}
						}
						
						codedPlace = cast(ulong)(maxPositions*(ret-space.v1.y)/cast(double)(space.v2.y-space.v1.y));
						break;
					}
					case PLAIN_DIR.Z_AXIS:
					{
						size_t inc = cast(size_t)((space.v2.z-space.v1.z)/maxPositions);
						if(inc == 0)
							inc = 1;
							
						for(size_t k = space.v1.z; k<space.v2.z; k+= inc)
						{
							left.v2.z = k;
							right.v1.z = k;
							auto sah = CostEmpty + left.volume*countAtVolume(left) + right.volume*countAtVolume(right);
							if( sah < cost )
							{
								cost = sah;
								ret = k;
							}
						}
						
						codedPlace = cast(ulong)(maxPositions*(ret-space.v1.z)/cast(double)(space.v2.z-space.v1.z));
						break;
					}	
				}
				return ret;
			}
				
			// считаем количество возможных положений плоскости
			ulong plainPositions = pow(2, plainPrecision);
			
			static if(plainPrecision == 0)
				return chooseSimple();
			else
			{
				// При указании 32 битов, число уже не помещается в ulong ровно на 1 значение и получаем 0
				assert(plainPositions != 0, "Plain positions is zero, try to decrease plainPrecision!");
				return chooseSAH(plainPositions);
			}
		}
		
		/**
		*	Проверяет, заполнен ли кусок массива subArr одним значением. Подмассив
		*	описывается структурой coord, в fillVal записывается значение, которым
		*	заполнен подмассив. 
		*/
		bool isOneValFilled(T)(in T[][][] data, out T fillVal, ref VolumeInfo!T coord)
		{
			T val;
			fillVal = T.init;
	
			bool first = true;
			for(size_t x = coord.v1.x; x<coord.v2.x; x++)
				for(size_t y = coord.v1.y; y<coord.v2.y; y++)
					for(size_t z = coord.v1.z; z<coord.v2.z; z++)
					{
						if(first) 
						{
							val = data[x][y][z];
							first = false;
						}
						if(data[x][y][z] != val) return false;
					}
			fillVal = val;
			return true;
		}		
	}
	
	// Данные
	private
	{
		/**
		*	Таблица цветов и материалов. Листья дерева имеют id 
		*	для получения цвета и материала из этой таблицы. 
		*	Нужно учитывать, что чем больше таблица, тем больший
		*	id нужно записывать в листья, тем больший объем памяти
		*	будет есться моделью. Оптимальный размер 256 цветов-
		*	материалов. 
		*/
		ColorInfo[] mColorTable;
		
		/**
		*	Модель может занимать очень много памяти (до нескольких гигабайт),
		*	поэтому выделение однородного куска памяти может быть проблематично.
		*	Класс позволяет создавать связные массивы данных и работать с ними
		*	как с единым массивом.
		*	
		*	Note:
		*		Размер итоговой модели все равно будет кратным байту, так как 
		*		системы аппаратно не умеют работать с данными меньше чем байт
		*		(memory aligment, побитно работают некоторые, но очень медленно).
		*/
		class ModelMemory(size_t bufferedBits = 128) : LinkedArray!(ubyte, chunkSize)
		{
			this()
			{
				mCurrChunks = new BitArray[1];
			}
			
			/**
			*	Записывает узел дерева в массив. Узел представляется как:
			*	[codedPlace:plainPrecision, isLeftNode:1, isRightNode:1]. Итого
			*	минимальный размер нода будет 2 бита.
			*/
			void writeNode(ulong codedPlace, bool isLeftNode, bool isRightNode)
			{
				// Храним временные биты
				BitArray bits;
				
				// Записываем положение плоскости
				static if(plainPrecision > 0)
				{
					auto m = nativeToLittleEndian(codedPlace);
					bits.init(m, plainPrecision);
				}
				// Добавляем флаги нодов/листов
				bits ~= isLeftNode;
				bits ~= isRightNode;
				
				// Записываем в итоговый массив
				currChunk ~= bits;
				
				// Проверка размера чанка
				checkChunk();
			}
			
			/**
			*	Записывает лист дерева в массив. Лист представляется как:
			*	[deleted:1, <color:colorTableBits>]. Если лист удален или
			*	пуст, первый бит равен 1, тогда дальше сразу идет следующий
			*	нод или лист, иначе далее записан индекс в таблице цвето-
			*	материалов. Минимальный размер листа - 1 бит.
			*/
			void writeLeaf(ulong colorIndex)
			{
				// Храним временные биты
				BitArray bits;
				
				// записываем стоп-бит
				if(colorIndex == 0)
				{
					bits ~= true;
					
					// И сразу выходим
					currChunk ~= bits;
					checkChunk();
					return;
				}	
				else
				{
					bits ~= false;
					
					// Записываем индекс
					auto m = nativeToLittleEndian(colorIndex);
					auto mbits = BitArray();
					mbits.init(m, colorTableBits);
					bits ~= mbits;
					
					// Выходим
					currChunk ~= bits;
					checkChunk();
					return;
				}		
			}
			
			/**
			*	Запись нового уровня дерева.
			*/
			void nextLevel(ulong size)
			{
				mLevels[currLevel++] = size;
			}
			
			/**
			*	Получение последнего уровня, записанного в массив.
			*/
			BitArray lastLevel() @property
			{
				if(cast(long)currLevel-2 < 0)
					return BitArray();
					
				BitArray array;
				auto subarr = this[mLevels[currLevel-2]..length];
				array.init(subarr, subarr.length*8);
				return array;
			}
			
			/**
			*	Итерирование по всем уровням глубины
			*/
			int opApply(int delegate(ref BitArray) dg)
			{
				int result = 0;
				
				for(ulong i =0; i<mLevels.keys.length; i++)
				{
					ulong end; 
					if(i+1 in mLevels)
						end = mLevels[i+1];
					else
						end = length;
						
					BitArray array;
					auto subarr = this[mLevels[i]..end];
					array.init(subarr, subarr.length*8);
					result = dg(array);
					if(result) 
						break;
				}
				return result;
			}
			
			/**
			*	Запись мета-информации о дереве в поток.
			*	К мете относится таблица смещений уровней дерева.
			*/
			ulong writeMeta(Stream stream)
			{
				ulong ret = stream.position;
				
				stream.write(cast(ulong)mLevels.keys.length);
				for(ulong i=0; i<mLevels.keys.length; i++)
				{
					stream.write(mLevels[i]);
				}
				
				return ret;
			}
			
			/**
			*	Чтение мета информации из потока.
			*/
			void readMeta(Stream stream)
			{
				scope(failure)
					throw new KdTreeFormatException(stream.position, "Failed to read meta-information!");
				
				mLevels.clear();
				
				ulong levels;
				stream.read(levels);
				for(ulong i=0; i<levels; i++)
					stream.read(mLevels[i]);
			}
			
			/**
			*	Запись самого дерева в поток, возвращает смещение в файле.
			*/
			ulong writeData(Stream stream)
			{
				ulong ret = stream.position;
				
				ulong dsize = length;
				stream.write(dsize);
				foreach(chunk; this.memoryChunks)
				{
					stream.writeExact(chunk.ptr, ubyte.sizeof*chunk.length);
				} 
				
				return ret;
			}
			
			/**
			*	Загружаем основную информацию о дереве из файла.
			*/
			void readData(Stream stream)
			{
				scope(failure)
					throw new KdTreeFormatException(stream.position, "Failed to read tree data!");
					
				ulong dsize;
				stream.read(dsize);
				
				while(dsize > 0)
				{
					size_t buffSize;
					if(dsize >= chunkSize)
					{
						buffSize = chunkSize;
						dsize -= chunkSize;
					} else
					{
						buffSize = cast(size_t)dsize;
						dsize = 0;
					}
					
					auto buff = new ubyte[buffSize];
					stream.readExact(buff.ptr, buffSize);
					this ~= buff;
				}	
			}
			
			private
			{
				/**
				*	Позволяет слайсить масссивы битов.
				*/
				BitArray sliceBitArray(ref BitArray source, size_t x, size_t y)
				{
					auto buff = new bool[y-x];
					for(size_t i = x; i < y && i < source.length; i++)
						buff[i-x] = source[i];
						
					BitArray ret;
					ret.init(buff);
					return ret;	
				}
				
				/**
				*	Получаем текущий кусок чанка для записи.
				*/
				ref BitArray currChunk() @property
				{
					return mCurrChunks[$-1];
				}
				
				/**
				*	Проверяет, не вышел ли размер чанка за дозволенный размер.
				*	Если вышел, записывает его и открывает новый.
				*/
				void checkChunk(bool forcedClose = false)
				{
					if(mCurrChunks[$-1].length >= bufferedBits)
					{
						mCurrChunks ~= sliceBitArray(mCurrChunks[$-1], bufferedBits, mCurrChunks[$-1].length);
						mCurrChunks[$-2] = sliceBitArray(mCurrChunks[$-2], 0, bufferedBits);
					}
					
					ulong size;
					foreach(ref chunk; mCurrChunks)
						size += chunk.dim;
						
					if(size >= chunkSize || forcedClose)
					{
						foreach(i, ref chunk; mCurrChunks)
						{
							/*if(i != mCurrChunks.length - 1)
							{
								auto needsBits = chunk.length % 8;
								if(needsBits == 0)
									this ~= cast(ubyte[])cast(size_t[])chunk;
								else // нужно добавить битов из следующего
								{
									chunk ~= sliceBitArray(mCurrChunks[i+1], 0, needsBits);
									mCurrChunks[i+1] = sliceBitArray(mCurrChunks[i+1], needsBits+1, mCurrChunks[i+1].length);
									this ~= cast(ubyte[])cast(size_t[])chunk;
								}
							} else
							{*/
								this ~= cast(ubyte[])cast(size_t[])chunk;								
							//}
						}
						mCurrChunks = new BitArray[1];
					}
				}
				
				/**
				*	Закрывает все чанки и возвращает длину обновленного массива в байтах.
				*/
				ulong finalize()
				{
					checkChunk(true);
					return length;
				}

			}
			private
			{
				ulong[ulong] mLevels;
				ulong currLevel;
				BitArray[] mCurrChunks;
			}
		}
		
		/// Хранит узлы и листья дерева
		ModelMemory!480 mMem;
		
		/// Храним размеры модели для корректного восстановления
		vec3ul mSize;
		
		/// Описывает текущее разбиваемое пространство
		struct VolumeInfo(T)
		{
			Vector!(size_t, 3) v1,v2;
			bool node = true;
			T val;
			
			this(size_t x1, size_t y1, size_t z1, size_t x2, size_t y2, size_t z2)
			{
				v1 = Vector!(size_t, 3)(x1,y1,z1);
				v2 = Vector!(size_t, 3)(x2,y2,z2);
			}
			
			// Считаем объем
			double volume() nothrow @property
			{
				return (v2.x-v1.x)*(v2.y-v1.y)*(v2.z-v1.z);
			}			
		}		
	}
}

unittest
{

}