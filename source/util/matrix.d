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
*   Реализует квадратные матрицы
*
*	Реализация квадратных матриц. Используется как посредник между OpenGL матрицами (просто массивы)
*	и системой рендеринга.
*	@todo Добавить методы для вычисления обратной матрицы
*	@todo Добавить юниттестов
*	@todo Добавить неквадратные матрицы (неприоритетно)
*	@todo Добавить функцию LookAt
*/
module util.matrix;

import std.math;
import util.common : Radian;
import std.conv;
import std.array;

public import util.vector;

private T[size] initArray(T,int size)(T value)
{
	T ret[size];
	foreach(ref a; ret)
		a = value;
	return ret;
}

/**
*	Исключение вызывается, когда происходит попытка
*	получить обратную матрицу для матрицы с нулевым
*	детерминантом.
*/
class MatrixNoInverse: Exception
{
	this()
	{
		super("Matrix has no inverse!");
	}
}

/// Квадратная матрица
/**
*	Нужна для удобной работы с кватернионами, векторами и связи
*	opengl матриц с этими объектами.
*	Как только понадобятся неквадратные матрицы, добавим.
*/
struct Matrix(size_t size)
{
	float m[size*size] = initArray!(float, size*size)(0.0f);
	
	alias Matrix!(size) thistype;
	alias Vector!(float, size) VecSize;
	
	/// Загрузка матрицы из массива
	/**
	*	Матрица представлена в памяти по столбцам, массив
	*	должен быть записан построчно.
	*/
	this(float[size*size] data)
	{
		assert(data.length == size*size, "Matrix expected data length "~to!string(size*size)~" not a "~to!string(data.length));
		foreach(size_t i,j, ref val; this)
			val = data[j+i*size];
	} 
	
	/**
	*	Загружаем матрицу из векторов-строк
	*/
	void loadFromRows(ref VecSize[size] rows)
	{
		foreach(size_t i, ref row; rows)
		{
			for(size_t j=0; j<size; j++)
				this[i,j] = row[j];
		}
	}
	
	/**
	*	Загружаем матрицу из векторов-столбцов
	*/
	void loadFromColumns(ref VecSize[size] columns)
	{
		foreach(size_t j, ref col; columns)
		{
			for(size_t i=0; i<size; i++)
				this[i,j] = col[i];
		}		
	}
	
	/// Получить матрицу, заполненную нулями
	@property static thistype zeros()
	{
		thistype mt;
		foreach(ref val;mt.m)
			val = 0.;
		return mt;
	}

	/// Получить единичную матрицу
	@property static thistype identity()
	{
		thistype mt = zeros;
		for(uint i = 0; i < size*size; i+=size+1)
			mt.m[i] = 1;
		return mt;
	}

	/// Получить матрицу, заполненную единицами
	@property static thistype ones()
	{
		thistype mt;
		foreach(ref val;mt.m)
			val = 1.;	
		return mt;
	}

	/// Доступ к элементу на чтение
	float opIndex(size_t i, size_t j)
	in
	{
		assert( i < size, "Matrix i index overflow!" );
		assert( j < size, "Matrix j index overflow!" );
	}
	body
	{
		return m[i+j*size];
	}

	/// Доступ к элементу на запись
	void opIndexAssign(float val, size_t i, size_t j)
	in
	{
		assert( i < size, "Matrix i index overflow!" );
		assert( j < size, "Matrix j index overflow!" );
	}
	body
	{
		m[i+j*size] = val;
	}

	/// Сложение матриц
	auto opBinary(string op)(thistype b) if(op=="+")
	{
		auto ret = thistype.zeros;
		foreach(i,ref val; ret.m)
			val = m[i]+b.m[i];
		return ret;
	}

	/// Вычитание матриц
	auto opBinary(string op)(thistype b) if(op=="-")
	{
		auto ret = thistype.zeros;
		foreach(i,ref val; ret.m)
			val = m[i]-b.m[i];
		return ret;
	}	

	/// Умножение на вектор
	vec4 opBinary(string op)(vec4 b) if(op=="*" && size == 4)
	{
		vec4 ret;
		ret.x = m[0]*b.x+m[4]*b.y+m[8]*b.z+m[12]*b.w;
		ret.y = m[1]*b.x+m[5]*b.y+m[9]*b.z+m[13]*b.w;
		ret.z = m[2]*b.x+m[6]*b.y+m[10]*b.z+m[14]*b.w;
		ret.w = m[3]*b.x+m[7]*b.y+m[11]*b.z+m[15]*b.w;
		return ret;
	}	

	/// Умножение на вектор
	vec3 opBinary(string op)(vec3 b) if(op=="*" && size == 3)
	{
		vec3 ret;
		ret.x = m[0]*b.x+m[3]*b.y+m[6]*b.z;
		ret.y = m[1]*b.x+m[4]*b.y+m[7]*b.z;
		ret.z = m[2]*b.x+m[5]*b.y+m[8]*b.z;
		return ret;
	}

	/// Умножение на вектор
	vec2 opBinary(string op)(vec2 b) if(op=="*" && size == 2)
	{
		vec2 ret;
		ret.x = m[0]*b.x+m[2]*b.y;
		ret.y = m[1]*b.x+m[3]*b.y;
		return ret;
	}

	/// Умножение матриц O(n^3)
	auto opBinary(string op)(thistype b) if(op=="*")
	{
		auto ret = thistype.zeros;
		foreach(size_t i,j, ref val; ret )
		{
			float summ = 0.;
			for(size_t r=0; r<size; r++)
			{
				summ += this[i,r]*b[r,j];
			}
			val = summ;
		}
		return ret;
	}

	/// Итерация по всем элементам матрицы
	int opApply(int delegate(ref float) dg)
	{
		foreach(ref val;m)
		{
			auto result = dg(val);
			if (result) return result;
		}
		return 0;
	}

	/// Итерация по всем элементам матрицы
	int opApply(int delegate(size_t, size_t, ref float) dg)
	{
		foreach(k,ref val;m)
		{
			auto result = dg(cast(size_t)(k%size), cast(size_t)(k/size), val);
			if (result) return result;
		}
		return 0;
	}

	/// Получение строки матрицы
	VecSize getRow(size_t i)
	{
		auto ret = new float[size];
		for(size_t j=0; j<size; j++)
		{
			ret[j] = this[i,j];
		}
		return VecSize(ret);
	}
	
	/// Получение стобца матрицы
	VecSize getColumn(size_t i)
	{
		auto ret = new float[size];
		for(size_t j=0; j<size; j++)
		{
			ret[j] = this[j,i];
		}
		return VecSize(ret);		
	}
	
	/// Перемена местами двух строк
	void swapRows(size_t i1, size_t i2)
	{
		auto temp = getRow(i2);
		for(size_t j=0; j<size; j++)
		{
			this[i2,j] = this[i1,j];
			this[i1,j] = temp[j];
		}	
	}
	
	/// Перемена местами двух столбцов
	void swapColumns(size_t i1, size_t i2)
	{
		auto temp = getColumn(i2);
		for(size_t j=0; j<size; j++)
		{
			this[j,i2] = this[j,i1];
			this[j,i1] = temp[j];
		}		
	}
	
	/// Домножает строку на коэфф.
	void mulRow(size_t i, float value)
	{
		for(size_t j=0; j<size; j++)
			this[i,j] = this[i,j]*value;
	}
	
	/// Домножает столбец на коэфф.
	void mulColumn(size_t j, float value)
	{
		for(size_t i=0; i<size; i++)
			this[i,j] = this[i,j]*value;
	}
	
	/// Сравнение двух матриц
	bool opEqual(thistype b)
	{
		bool ret = true;
		foreach(i, ref val; m)
			ret = ret && val == b.m[i];
		return ret;
	}

	/// Примерное сравнение двух матриц
	bool approxEqual(thistype b)
	{
		bool ret = true;
		foreach(i, ref val; m)
			ret = ret && std.math.approxEqual(val,b.m[i]);
		return ret;		
	}
	
	/// Получение указателя для работы с опенжл матрицей
	float* toOpenGL()
	{
		return &m[0];
	}

	/// Вывод матрицы в строку
	string toString()
	{
		auto s = appender!string();
		for(size_t i=0; i<size; i++)
		{
			s.put("| ");
			for(size_t j=0; j<size; j++)
			{
				s.put(to!string(this[i,j]));
				s.put(" ");
			}
			s.put("|\n");
		}
		return s.data;
	}
	
	/// Создание матрицы из массива
	/**
	*	Warning: Опасная функция, размеры матриц должны совпадать!
	*/
	static thistype fromOpenGL(float* glMatr)
	{
		thistype ret;
		foreach(i,ref val; ret.m)
			val = glMatr[i];
		return ret;
	}

	/// Получение транспонированной матрицы
	thistype transpose() @property
	{
		auto ret = thistype.zeros;
		foreach(i, j, val; this)
			ret[j,i] = val;
		return ret;
	}
	
	
	/// Получение определителя матрицы
	double determinant() @property
	{
		static if(size == 1) return m[0];
		else
		{
			// Копируем матрицу
			thistype matrix = this;
			
			// Колво перестановок
			uint s = 0;
			
			// Приводим к треугольной
			mainloop: for(size_t i = 0; i<size; i++)
			{
				// Частный случай, меняем строки местами, если первый элемент нулевой
				if(matrix[i,i] == 0)
				{
					bool failed = true;
					for(size_t m=i+1; m<size; i++)
					{
						if(matrix[m,i] != 0)
						{
							s++;
							matrix.swapRows(i, m);
							failed = false;
							break;
						}
					}
					if(failed) break mainloop;				
				}
				// Вычитаем строки
				for(size_t j = i+1; j<size; j++)
				{
					matrix.substractRows(j, i, matrix[j,i]/matrix[i,i]);
				}
			}
			
			// Определитель треугольной матрицы = произведение элементов на главной диагонали
			double ret = 1;
			for(size_t i = 0; i<size; i++)
				ret *= matrix[i,i];
			// Подправим знак с учетом перестановок
			if(s % 2 == 1)
			{
				ret *= -1;
			}	
			return ret;	
		}	
	} 
	
	/// Получение обратной матрицы
	/**
	*	Если обратной матрицы не существует (det == 0) кидается
	*	исключение MatrixNoInverse.
	*/
	thistype inverse() @property
	{
		if(this.determinant == 0) 
			throw new MatrixNoInverse();
			
		static if(size == 1) return 1/m[0];
		else
		{
			// Матрица, к которой будем применять действия
			thistype ret = thistype.identity;
			thistype matrix = this;
			
			// Приводим к треугольной, прямой проход 
			mainloop: for(size_t i = 0; i<size; i++)
			{
				// Частный случай, меняем строки местами, если первый элемент нулевой
				if(matrix[i,i] == 0)
				{
					bool failed = true;
					for(size_t m=i+1; m<size; i++)
					{
						if(matrix[m,i] != 0)
						{
							ret.swapRows(i, m);
							matrix.swapRows(i, m);
							failed = false;
							break;
						}
					}
					if(failed) break mainloop;				
				}
				// Делим на первый элемент
				ret.mulRow(i, 1/matrix[i,i]);
				matrix.mulRow(i, 1/matrix[i,i]);
				// Вычитаем строки
				for(size_t j = i+1; j<size; j++)
				{
					ret.substractRows(j, i, matrix[j,i]);
					matrix.substractRows(j, i, matrix[j,i]);
				}
			}
			
			// Приводим к единичной, обратный проход
			for(size_t i=size-1; i>0; i--)
			{
				for(ptrdiff_t j=i-1; j>=0; j--)
				{
					ret.substractRows(j, i, matrix[j,i]);
					matrix.substractRows(j, i, matrix[j,i]);				
				} 
			}
			
			return ret;	
		}				
	}
	
	/**
	*	Решение Гауссом-Жорданом (или правильнее Йорданом) системы линейных уравнений со 
	*	свободным столбцом freeColumn, и основной матрицей this. Если обратной матрицы неъ
	*	существует (det == 0) кидается исключение MatrixNoInverse.
	*/
	VecSize solveLinear(in VecSize freeColumn)
	{
		if(this.determinant == 0) 
			throw new MatrixNoInverse();
			
		static if(size == 1) return VecSize(freeColumn[0]/m[0]);
		else
		{
			// Вектор, к которому будем применять действия
			VecSize ret = freeColumn;
			thistype matrix = this;
			
			// Приводим к треугольной, прямой проход 
			mainloop: for(size_t i = 0; i<size; i++)
			{
				// Частный случай, меняем строки местами, если первый элемент нулевой
				if(matrix[i,i] == 0)
				{
					bool failed = true;
					for(size_t m=i+1; m<size; i++)
					{
						if(matrix[m,i] != 0)
						{
							auto temp = ret[i];
							ret[i] = ret[m];
							ret[m] = temp;
							
							matrix.swapRows(i, m);
							failed = false;
							break;
						}
					}
					if(failed) break mainloop;				
				}
				// Делим на первый элемент
				ret[i] = ret[i]/matrix[i,i]; 
				matrix.mulRow(i, 1/matrix[i,i]);
				// Вычитаем строки
				for(size_t j = i+1; j<size; j++)
				{
					ret[j] = ret[j]-ret[i]*matrix[j,i];
					matrix.substractRows(j, i, matrix[j,i]);
				}
			}
			
			// Приводим к единичной, обратный проход
			for(size_t i=size-1; i>0; i--)
			{
				for(ptrdiff_t j=i-1; j>=0; j--)
				{
					ret[j] = ret[j]-ret[i]*matrix[j,i];
					matrix.substractRows(j, i, matrix[j,i]);			
				} 
			}
			
			
			return ret;	
		}						
	}
	
	/**
	*	Приведение матрицы к ступенчатому виду
	*/
	thistype rowEchelon() @property
	{
		import std.stdio;
		
		static if(size == 1) return this;
		else
		{
			thistype matrix = this;
			
			// Приводим к треугольной, прямой проход 
			mainloop: for(size_t i = 0; i<size; i++)
			{
				// Частный случай, меняем строки местами, если первый элемент нулевой
				if(matrix[i,i] == 0)
				{
					bool failed = true;
					for(size_t m=i+1; m<size; i++)
					{
						if(matrix[m,i] != 0)
						{
							matrix.swapRows(i, m);
							failed = false;
							break;
						}
					}
					if(failed) break mainloop;				
				}
				// Делим на первый элемент
				matrix.mulRow(i, 1/matrix[i,i]);
				// Вычитаем строки
				for(size_t j = i+1; j<size; j++)
				{
					matrix.substractRows(j, i, matrix[j,i]);
				}
				
				//debug writeln(matrix.toString());
			}
			return matrix;
		}		
	}
	
	/**
	*	Вычисление ранга матрицы.
	*/
	size_t rang() @property
	{
		auto matrix = rowEchelon;
		
		size_t ret = 0;
		for(size_t i = 0; i<size; i++)
		{
			if(matrix.getRow(i) != VecSize(0.0f,0.0f,0.0f))
				ret+=1;
		}
		return ret;							
	}
	
	/**
	*	Для каждого элемента матрицы применяет функцию func с заданным набором аргументов args.
	*/
	void apply(alias func)()
	{
		static assert(__traits(compiles, "func(0.0f)"), "Function "~func.stringof~" cannot be called with (float)");
		foreach(i,j,ref val; this)
			val = func(val);
	}
		

	private
	{
		/// Вычитание из строки матрицы другой строки, домноженной на коэфф. 
		void substractRows(size_t k1, size_t k2, double val)
		{
			auto kv2 = getRow(k2)*val;
			for(size_t i = 0; i<size; i++)
			{
				this[k1,i] = this[k1,i]-kv2[i];
			}
		}	
	}
}

// Это базовые тесты, проверка вообще на работоспособность. В будущем нужно добавить лучшие.
unittest
{
	import std.stdio;

	write("Testing matrixes module...");
	scope(success) writeln("Finished!");
	scope(failure) writeln("Failed!");
	
	auto a = Matrix!(2).zeros;
	auto b = Matrix!(2).ones;
	auto c = Matrix!(2).identity;

	assert(a[0,0] == 0, "Generation zeros fails!");
	assert(b[0,0] == 1, "Generation ones fails!");
	assert(c[0,0] == 1 && c[1,0] == 0, "Generation identity fails!");
	
	b = b+b;
	assert(b[0,0] == 2 && b[1,0] == 2 && b[0,1] == 2 && b[1,1] == 2, "Summing failed!");

	b = c*b;
	assert(b[0,0] == 2 && b[1,0] == 2 && b[0,1] == 2 && b[1,1] == 2, "Multiplication failed!");

	auto aa = Matrix!(4).zeros;
	aa[0,0] = 1; aa[0,1] = 2; aa[0,2] = 3; aa[0,3] = 4;
	aa[1,0] = 5; aa[1,1] = 6; aa[1,2] = 7; aa[1,3] = 8;
	aa[2,0] = 9; aa[2,1] = 10; aa[2,2] = 11; aa[2,3] = 12;
	aa[3,0] = 13; aa[3,1] = 14; aa[3,2] = 15; aa[3,3] = 16;

	auto bb = Matrix!(4).zeros;
	bb[0,0] = 16; bb[0,1] = 15; bb[0,2] = 14; bb[0,3] = 13;
	bb[1,0] = 12; bb[1,1] = 11; bb[1,2] = 10; bb[1,3] = 9;
	bb[2,0] = 8; bb[2,1] = 7; bb[2,2] = 6; bb[2,3] = 5;
	bb[3,0] = 4; bb[3,1] = 3; bb[3,2] = 2; bb[3,3] = 1;

	Matrix!(4) cc = aa*bb;

	assert(
		cc[0,0] == 80 && cc[0,1] == 70 && cc[0,2] == 60 && cc[0,3] == 50 &&
		cc[1,0] ==240 && cc[1,1] ==214 && cc[1,2] ==188 && cc[1,3] ==162 &&
		cc[2,0] ==400 && cc[2,1] ==358 && cc[2,2] ==316 && cc[2,3] ==274 &&
		cc[3,0] ==560 && cc[3,1] ==502 && cc[3,2] ==444 && cc[3,3] ==386,"Multiplication failed!");

	auto aat = aa.transpose;
	assert(
		aat[0,0] == 1 && aat[0,1] == 5 && aat[0,2] == 9 && aat[0,3] == 13 &&
		aat[1,0] == 2 && aat[1,1] == 6 && aat[1,2] ==10 && aat[1,3] == 14 &&
		aat[2,0] == 3 && aat[2,1] == 7 && aat[2,2] ==11 && aat[2,3] == 15 &&
		aat[3,0] == 4 && aat[3,1] == 8 && aat[3,2] ==12 && aat[3,3] == 16,"Transpose failed!");	
	
	// Тестим определитель
	auto m1 = Matrix!(3)([
		1.0f, 2.0f, 3.0f,
		4.0f, 5.0f, 6.0f,
		7.0f, 8.0f, 9.0f
		]);
	assert(m1.determinant == 0, "Determinant failed!");
	
	auto m2 = Matrix!(3)([
		0.0f, 1.0f, 1.0f,
		1.0f, 0.0f, 0.0f,
		2.0f, 2.0f, 2.0f
		]);
	assert(m2.determinant == 0, "Determinant failed!");
	
	auto m3 = Matrix!(3)([
		4.0f, 1.0f, 1.0f,
		1.0f, 0.0f, 0.0f,
		0.0f, 0.0f, 2.0f
		]);
	assert(m3.determinant == -2, "Determinant failed!");	
	
	auto m4 = Matrix!(3)([
		4.0f, 1.0f, 1.0f,
		1.0f, 0.0f, 5.0f,
		0.0f,25.0f, 2.0f
		]);
	assert(m4.determinant == -477, "Determinant failed!");		
	
	// Тестим обратную матрицу
	auto m5 = Matrix!(3)([
		1.0f, 1.0f, 1.0f,
		4.0f, 2.0f, 1.0f,
		9.0f, 3.0f, 1.0f		
		]);
	auto m5i = Matrix!(3)([
		 0.5f,-1.0f, 0.5f,
		-2.5f, 4.0f,-1.5f,
		 3.0f,-3.0f, 1.0f		
		]);
	assert(m5.inverse == m5i, "Inverse failed!");
	
	auto m6 = Matrix!(3)([
		3.0f, 2.0f, 2.0f,
		1.0f, 3.0f, 1.0f,
		5.0f, 3.0f, 4.0f		
		]);
	auto m6i = Matrix!(3)([
		  1.8f,-0.4f,-0.8f,
		  0.2f, 0.4f,-0.2f,
		 -2.4f, 0.2f, 1.4f		
		]);
	assert(m6.inverse.approxEqual(m6i), "Inverse failed!");	
	
	// Тестим Гаусса-Жордана
	auto m7 = Matrix!(3)([
		1.0f, 1.0f, 1.0f,
		4.0f, 2.0f, 1.0f,
		9.0f, 3.0f, 1.0f		
		]);	
	auto m7free = m7.VecSize(0,1,3);
	assert(m7.solveLinear(m7free) == m7.VecSize(0.5,-0.5,0), "Linear solve failed!");
	
	// Тестим apply
	auto m8 = Matrix!(3)([
		1.0f, 1.0f, 1.0f,
		4.0f, 2.0f, 1.0f,
		9.0f, 3.0f, 1.0f		
		]);	
	
	auto m8e = Matrix!(3)([
		E, E, E,
		exp(4.0f), exp(2.0f), E,
		exp(9.0f), exp(3.0f), E		
		]);	
	m8.apply!(exp)();
	
	assert(m8.approxEqual(m8e), "Apply failed!");	
	
	// Тестим ранг матрицы
	auto m9 = Matrix!(3)([
		-0.17f, 0.17f, 0.0f,
		0.0f, -0.17f, 0.17f,
		0.08f, 0.0f, -0.08f		
		]);
	assert(m9.rang == 2, "Rang failed!");
}

/// Получение матрицы перемещения
Matrix!4 translateMtrx(float x, float y, float z)
{
	Matrix!4 ret;
	ret[0,0] = 1.0f; ret[0,1] = 0.0f; ret[0,2] = 0.0f; ret[0,3] = x;
	ret[1,0] = 0.0f; ret[1,1] = 1.0f; ret[1,2] = 0.0f; ret[1,3] = y;
	ret[2,0] = 0.0f; ret[2,1] = 0.0f; ret[2,2] = 1.0f; ret[2,3] = z;
	ret[3,0] = 0.0f; ret[3,1] = 0.0f; ret[3,2] = 0.0f; ret[3,3] = 1.0f;
	return ret;
} 

/// Получение матрицы масштабирования
Matrix!4 scaleMtrx(float x, float y, float z)
{
	Matrix!4 ret;
	ret[0,0] = x   ; ret[0,1] = 0.0f; ret[0,2] = 0.0f; ret[0,3] = 0.0f;
	ret[1,0] = 0.0f; ret[1,1] = y   ; ret[1,2] = 0.0f; ret[1,3] = 0.0f;
	ret[2,0] = 0.0f; ret[2,1] = 0.0f; ret[2,2] = z   ; ret[2,3] = 0.0f;
	ret[3,0] = 0.0f; ret[3,1] = 0.0f; ret[3,2] = 0.0f; ret[3,3] = 1.0f;
	return ret;
} 

/// Получение матрицы поворота из Эйлоровых углов
Matrix!4 rotationMtrx(float pitch, float yaw, float roll)
{
	Matrix!4 ret;
	ret[0,0] = cos(yaw)*cos(roll); 	ret[0,1] = -cos(pitch)*sin(roll)+sin(pitch)*sin(yaw)*cos(roll); 	ret[0,2] = sin(pitch)*sin(roll)+cos(pitch)*sin(yaw)*cos(roll); 	ret[0,3] = 0.0f;
	ret[1,0] = cos(yaw)*sin(roll); 	ret[1,1] = cos(pitch)*cos(roll)+sin(pitch)*sin(yaw)*sin(roll); 		ret[1,2] = -sin(pitch)*cos(roll)+cos(pitch)*sin(yaw)*sin(roll); ret[1,3] = 0.0f;
	ret[2,0] = -sin(yaw); 			ret[2,1] = sin(pitch)*cos(yaw); 									ret[2,2] = cos(pitch)*cos(yaw); 								ret[2,3] = 0.0f;
	ret[3,0] = 0.0f; 				ret[3,1] = 0.0f; 													ret[3,2] = 0.0f; 												ret[3,3] = 1.0f;
	return ret;	
}

unittest
{
	import std.stdio;
	import std.conv;
	import std.math;
	import util.vector;

	write("Testing rotation matrix... ");
	scope(success) writeln("Finished!");
	scope(failure) writeln("Failed!");
	
	vec4 a = vec4(1,0,0,1);
	a = rotationMtrx(0,PI/2.,0)*a;
	assert(approxEqual(a.x,0) && approxEqual(a.z, -1) && a.y == 0 && a.w == 1, "Vertex rotation failed: "~to!string(a));

	a = rotationMtrx(PI/2, 0, 0)*a;
	assert(approxEqual(a.x,0) && approxEqual(a.y, 1) && approxEqual(a.z, 0) && a.w == 1, "Vertex rotation failed: "~to!string(a));
}

/// Получение матрицы поворота из Эйлоровых углов
/**
*	@note Точная копия функции для 4х мерных векторов.
*/
Matrix!3 rotationMtrx3(float pitch, float yaw, float roll)
{
	Matrix!3 ret;
	ret[0,0] = cos(yaw)*cos(roll); 	ret[0,1] = -cos(pitch)*sin(roll)+sin(pitch)*sin(yaw)*cos(roll); 	ret[0,2] = sin(pitch)*sin(roll)+cos(pitch)*sin(yaw)*cos(roll); 
	ret[1,0] = cos(yaw)*sin(roll); 	ret[1,1] = cos(pitch)*cos(roll)+sin(pitch)*sin(yaw)*sin(roll); 		ret[1,2] = -sin(pitch)*cos(roll)+cos(pitch)*sin(yaw)*sin(roll); 
	ret[2,0] = -sin(yaw); 			ret[2,1] = sin(pitch)*cos(yaw); 									ret[2,2] = cos(pitch)*cos(yaw); 								
	return ret;	
}

/// Получить матрицу проекции
/**
*	Эта матрица переводит координаты камеры в оконные
*	@par fovy Угол обзора. Обычно [30..90] градусов, задается в радианах
*	@par aspect Отношение высоты экрана к его ширине
*	@par zNear Ближняя плоскость отсечения, брать как можно большую
*	@par zFar Дальняя плоскость отсченеия, брать как можно меньшую
*	@note Полученная матрица используется для получения MVP матрицы (Model-View-Projection)
*/
Matrix!4 projection(Radian fovy, float aspect, float zNear, float zFar)
{
	import std.stdio;
	//	writeln(fovy);
		
	float top = zNear*tan(fovy/2.0f);
	float right = top / aspect;

	/*Matrix!4 getProj(float l, float r, float b, float t, float n, float f)
	{
		Matrix!4 ret;
		ret[0,0] = 2*n/(r-l); 	ret[0,1] = 0.0f; 		ret[0,2] = (r+l)/(r-l); 		ret[0,3] = 0.0f;
		ret[1,0] = 0.0f; 		ret[1,1] = 2*n/(t-b); 	ret[1,2] = (t+b)/(t-b); 		ret[1,3] = 0.0f;
		ret[2,0] = 0.0f; 		ret[2,1] = 0.0f; 		ret[2,2] = -(f+n)/(f-n); 		ret[2,3] = -2*f*n/(f-n);
		ret[3,0] = 0.0f; 		ret[3,1] = 0.0f; 		ret[3,2] = -1.0f; 				ret[3,3] = 0.0f;	
		return ret;
	}*/

	Matrix!4 getProj(float r, float t, float n, float f)
	{
		Matrix!4 ret;
		ret[0,0] = n/r; 		ret[0,1] = 0.0f; 		ret[0,2] = 0.0f; 				ret[0,3] = 0.0f;
		ret[1,0] = 0.0f; 		ret[1,1] = n/t; 		ret[1,2] = 0.0f; 				ret[1,3] = 0.0f;
		ret[2,0] = 0.0f; 		ret[2,1] = 0.0f; 		ret[2,2] = -(f+n)/(f-n); 		ret[2,3] = -2*f*n/(f-n);
		ret[3,0] = 0.0f; 		ret[3,1] = 0.0f; 		ret[3,2] = -1.0f; 				ret[3,3] = 0.0f;	
		return ret;
	}

	return getProj(right, top, zNear, zFar);
}

/// Получить матрицу камеры
/**
*	Матрица переводит координаты мира в координаты камеры
*	@par eye Положение камеры
*	@par at Куда смотрит камера
*	@par up Направление вверх
*	@note Полученная матрица используется для получения MVP матрицы (Model-View-Projection)
*/
Matrix!4 lookAt(vec3 eye, vec3 at, vec3 up)
{
	auto zaxis = at-eye;
	zaxis.normalize();
	auto xaxis = up.cross(zaxis);
	xaxis.normalize();
	auto yaxis = zaxis.cross(xaxis);

	Matrix!4 ret;
	//ret[0,0] = xaxis.x;         ret[0,1] = yaxis.x;         ret[0,2] = zaxis.x;         ret[0,3] = 0.0f;
	//ret[1,0] = xaxis.y;         ret[1,1] = yaxis.y;         ret[1,2] = zaxis.y;         ret[1,3] = 0.0f;
	//ret[2,0] = xaxis.z;         ret[2,1] = yaxis.z;         ret[2,2] = zaxis.z;         ret[2,3] = 0.0f;
	//ret[3,0] = -xaxis.dot(eye); ret[3,1] = -yaxis.dot(eye); ret[3,2] = -zaxis.dot(eye); ret[3,3] = 1.0f;	
	
	ret[0,0] = xaxis.x;         ret[0,1] = xaxis.y;         ret[0,2] = xaxis.z;         ret[0,3] = -xaxis.dot(eye);
	ret[1,0] = yaxis.x;         ret[1,1] = yaxis.y;         ret[1,2] = yaxis.z;         ret[1,3] = -yaxis.dot(eye);
	ret[2,0] = zaxis.x;         ret[2,1] = zaxis.y;         ret[2,2] = zaxis.z;         ret[2,3] = -zaxis.dot(eye);
	ret[3,0] = 0.0f; 			ret[3,1] = 0.0f; 			ret[3,2] = 0.0f; 			ret[3,3] = 1.0f;	

	return ret;	
}

/// TransformedVector = ScaleMatrix * RotationMatrix * TranslationMatrix * OriginalVector;
