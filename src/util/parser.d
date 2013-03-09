//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/// Парсер формата gendoc
/**
*	@file parser.d Парсер для древовидного формата данных gendoc. Может читать также формат json и формат моделей mdl для WarcraftIII.
*	Используется как главный формат хранения материалов.
*/
// Written in the D programming language
/**
*	Module provides support for 'General Document' (etc gendoc) format. It is human-readable format for tree structure serialization. It's look like
*	JSON and YAML, due some lucky occasions parser can read JSON format and WarIII model format, althrough in read-only mode. Some examples below:
*
*	Example:
*	---------
*	// Comments are supported
*	SectionKey1 Value1 Value2 Value3 // and so on
*	{
*		Node1, // node without parameters, only key
*		Node2 Value, // node with one parameter
*		Node3 [Val1, Val2, Val3], // node with multiply pars
*		
*		Mod1 Mod2 Mod3 Node4 Value, // multiply modificators are supported
*		Mod1 Node5, // but this will be recognized as well as Node2, see TODO
*
*		// Nesting subsection
*		SubSectionKey1 Value1 Value2 Value3 // and so on
*		{
*			//...
*		}
*	}
*
*	// At root level supported only sections
*	SectionKey2 { 
*	
*	}
*	---------
*
*	Version: 1.0
*	Authors: Gushcha Anton (NCrashed)
*
*	TODO: multi line comments, 
*		
*/
module util.parser;

import std.stream;
import std.array;
import std.conv;
import std.string;
import std.algorithm;
import std.traits;

import util.singleton;
import util.common;

enum ROOT_TREE_NAME = "Root";

/// Класс-хранилище для системы конвертации строк
/**
*	@note Нужен для унификации процесса конвертации для 
*	DocNodeTree и DocNode.
*/
private class Converter
{
protected:
	/// Конвертация в строку
	T convert(T)(string s) if(is(T == string))
	{
		return trimString(s);
	}

	/// Конвертация в остальные типы
	T convert(T)(string s) if(isBasicType!T)
	{
		return to!T(s);
	}

	string trimString(string s)
	{
		if( s.length >= 2 && s[0]=='"' && s[$-1]=='"')
			return s[1..$-1];
		return s;		
	}
}

/// Лист дерева
class DocNode : Converter
{
public:

	this()
	{
		mMods = new string[0];
		mVals = new string[0];
	}

	/// Название листа
	string key() @property
	{
		return mKey;
	}

	/// Название листа
	void key(string val) @property
	{
		mKey = val;
	}

	/// Модификаторы
	const(string[]) mods() @property
	{
		return mMods;
	}

	/// Голые значения
	const(string[]) vals() @property
	{
		return mVals;
	}

	/// Кол-во значений
	size_t valsLength() @property
	{
		return mVals.length;
	}

	/// Проверка наличия модификатора
	bool hasMod(string mod)
	{
		foreach(s; mMods)
			if(mod == trimString(s))
				return true;
		return false;
	}

	/**
	*	Adding modificator to node
	*/
	void addMod(string mod)
	{
		mMods ~= mod;
	}

	string getMod(size_t i)
	{
		return trimString(mMods[i]);
	}

	/**
	*	Adding value to node
	*/
	void addVal(string val)
	{
		mVals ~= val;
	}

	/// Получение значения, сконвертированного в нужный тип
	/**
	*	@note Кавычки у строк отсекаются
	*/
	T getVal(T)(size_t i)
	{
		if(i >= mVals.length) return T.init;

		return convert!T(mVals[i]);
	}

	/// Копирование
	DocNode dup() @property
	{
		auto ret = new DocNode;
		ret.mKey = mKey;
		ret.mMods = mMods.dup;
		ret.mVals = mVals.dup;
		return ret;
	}

private:
	string mKey;
	string[] mMods;
	string[] mVals;
}

/// Узел дерева файла
class DocNodeTree : Converter
{
public:
	this()
	{
		mVals = new string[0];
		mSections = new DocNodeTree[0];
		mNodes = new DocNode[0];
	}

	/// Название листа
	string key() @property
	{
		return mKey;
	}

	/**
	*	Setting section primary key
	*/
	void key(string val) @property
	{
		mKey = val;
	}

	/// Дополнительные значения
	const(string[]) vals() @property
	{
		return mVals;
	}

	/**
	*	Adding new value $(D val) to sections values
	*/
	void addVal(string val)
	{
		mVals ~= val;
	}

	/// Подузлы дерева
	DocNodeTree[] sections() @property
	{
		return mSections;
	}

	/// Листы дерева
	DocNode[] nodes() @property
	{
		return mNodes;
	}

	/// Получение доп. значения, сконвертированного в нужный тип
	/**
	*	@note Кавычки у строк отсекаются
	*/
	T getVal(T)(size_t i)
	{
		if(i >= mVals.length) return T.init;

		return convert!T(mVals[i]);
	}

	/// Копирование
	DocNodeTree dup() @property
	{
		auto ret = new DocNodeTree;
		ret.mKey = mKey;
		ret.mVals = mVals.dup;
		foreach(node; mNodes)
			ret.mNodes ~= node.dup;
		foreach(sec; mSections)
			ret.mSections ~= sec.dup;
		return ret;
	}

	/// Колво листов дерева
	size_t nodesLength() @property
	{
		return mNodes.length;
	}

	/// Колво подузлов
	size_t sectionsLength() @property
	{
		return mSections.length;
	}

	/// Получение подсекции
	DocNodeTree subSection(size_t i)
	{
		if(i>sectionsLength) return null;
		return mSections[i];
	}

	/// Получение подсекции по имени
	DocNodeTree subSection(string name)
	{
		foreach(sec; mSections)
			if(sec.key == name)
				return sec;
		return null;
	}

	/// Получение подсекции по имени и доп. значениями
	DocNodeTree subSection(string name, string[] values...)
	{
		foreach(sec; mSections)
			if(sec.key == name)
				if(values.length <= sec.vals.length)
				{
					bool ret = true;
					foreach(i,val; values)
						ret = ret && trimString(sec.vals[i]) == val;
					if(ret) return sec;
				}
		return null;		
	}

	/// Добавление поддерева
	/**
	*	
	*/
	void addSubSection(DocNodeTree tree)
	{
		mSections ~= tree;
	}

	/// Удаление поддерева
	void removeSubSection(size_t i)
	{
		if(i >= sectionsLength) return;
		mSections = mSections[0..i]~mSections[i+1..$];
	}

	/// Получение листа по индексу
	/**
	*	@return null если не существует
	*/
	DocNode getNode(size_t i)
	{
		if(i >= nodesLength) return null;
		return mNodes[i];
	}

	/// Получение листа по имени
	/**
	*	@return null если не существует
	*/
	DocNode getNode(string name)
	{
		foreach(node; mNodes)
			if(node.key == name)
				return node;
		return null;
	}

	/// Получение списка листов с модификатором
	DocNode[] getNodes(string mod)
	{
		auto ret = new DocNode[0];
		foreach(node; mNodes)
			if(node.hasMod(mod))
				ret ~= node;
		return ret;
	}

	/// Добавление листа
	/**
	*	
	*/
	void addNode(DocNode node)
	{
		mNodes ~= node;
	}

	/// Удаление листа
	void removeNode(size_t i)
	{
		if(i >= nodesLength) return;
		mNodes = mNodes[0..i]~mNodes[i+1..$];
	}
private:
	string mKey;
	string[] mVals;
	DocNodeTree[] 	mSections;
	DocNode[]		mNodes;
}

/// Парсер для документов формата gendoc
/**
*	@note Также подходит для чтения форматов JSON и MDL WCR3.
*	@remarks Предназначен для чтения и записи файлов в виде деревьев,
*	и поддерживается принцип "Должен существовать один — и, желательно,
*	только один — очевидный способ сделать это."
*/
class DocParser
{
public:
	import std.stdio;
	/// Чтение файла
	/**
	*	@param file поток файла
	*	@return Прочитанное дерево документа
	*/
	DocNodeTree parse(Stream file)
	{
		mFile = file;

		//buffSize = getBufferSize();
		//buff = new char[buffSize];
		str = "";

		readToBuff();
		file.close();
		DocNodeTree tree = new DocNodeTree();
		tree.mKey = ROOT_TREE_NAME;

		while(!str.empty)
		{
			DocNodeTree subTree;
			try
			{
				subTree = readSection(str);
			}
			catch(Exception e)
			{
				// Перебрасывание болей общей ошибки
				throw new Exception("Failed to parse file! Reason: "~e.msg);
			}
			str = strip(str);
			tree.addSubSection(subTree);
		}

		return tree;
	}

	/// Запись в файл
	/**
	*	@param file Файл, куда будет записываться информация.
	*	@param tree Дерево файла
	*	@attention Листы на нулевом уровне будут проигнорированы!
	*/
	void write(Stream file, DocNodeTree tree)
	{
		if (tree is null) return;
		mFile = file;

		try
		{
			foreach(sec; tree.sections)
				writeSection(sec);
		}
		catch(Exception e)
		{
			throw new Exception("Failed to write doc file! Reason: "~e.msg);
		}
	}

private:
	/// Текущий файл, для чтения или записи
	Stream mFile;

	/// Обработанные строки
	string str;

	static string bells = [to!char(0x07)].idup;
	static string tabs = [to!char(0x09)].idup;
private:

	/// Чтение в буффер
	/**
	*	Построчное чтение в буффер с удалением лишних символов и прочего мешающего
	*	парсингу мусора
	*/
	void readToBuff()
	{
		size_t index = 0;
		while(!mFile.eof)
		{
			auto buff = mFile.readLine();

			index++;
			string s = strip(buff.idup);
			if(!s.empty)
			{
				// Удаление комментариев
				auto res = findSplit(s, "//");
				s = res[0];

				// Обработка длинных значений
				if(count(s, `"`)%2 != 0)
					throw new Exception(text("Line ",index," has imbalanced count of \"!"));
				auto pos1 = countUntil(s, `"`);
				auto pos2 = findPos(s, pos1+1, `"`);
				while(pos1>0 && pos2>0)
				{
					s = s[0..pos1]~replace(s[pos1..pos2], " ", bells)~s[pos2..$];
					s = s[0..pos1]~replace(s[pos1..pos2], "[", `\[`)~s[pos2..$];
					s = s[0..pos1]~replace(s[pos1..pos2], "]", `\]`)~s[pos2..$];
					s = s[0..pos1]~replace(s[pos1..pos2], "(", `\(`)~s[pos2..$];
					s = s[0..pos1]~replace(s[pos1..pos2], ")", `\)`)~s[pos2..$];
					s = s[0..pos1]~replace(s[pos1..pos2], "{", `\{`)~s[pos2..$];
					s = s[0..pos1]~replace(s[pos1..pos2], "}", `\}`)~s[pos2..$];

					pos1 = findPos(s, pos2+1, `"`);
					pos2 = findPos(s, pos1+1, `"`);
				}

				// Замена табуляций
				s = replace(s, tabs, " ");

				// Удаление дублированных пробелов
				while(countUntil(s, "  ")!=-1)
					s = replace(s, "  ", " ");

				if(!s.empty)
					str ~= s~" ";
			}
		}
		// Удаление дублированных пробелов
		while(countUntil(str, "  ")!=-1)
			str = replace(str, "  ", " ");
	}

	/// Замена всех символов 0x07 на пробелы
	string bell2Space(string s)
	{
		s = replace(s, bells, " ");
		s = replace(s, `\[`, "[");
		s = replace(s, `\]`, "]");
		s = replace(s, `\(`, "(");
		s = replace(s, `\)`, ")");
		s = replace(s, `\{`, "{");
		s = replace(s, `\}`, "}");
		return s;
	}

	/// Чтение секции
	/**
	*	Откусывается кусок от буфера
	*/
	DocNodeTree readSection(ref string s)
	{
		if(s.empty) throw new Exception("Passed empty string!");

		auto pos = countUntilEscaped(s, "{");
		if(pos < 0)
		{
			throw new Exception("Cannot find section opening bracket!");
		}

		auto close = getCloseBracket(s);
		if(close < 0)
		{
			throw new Exception("Cannot find section closing bracket!");
		}

		string head = strip(s[0..pos]);
		string sbody = strip(s[pos+1..close]);

		if(close+1>=s.length)
			s = "";
		else
			s = s[close+1..$];

		auto tree = new DocNodeTree;
		// Распознование имени
		pos = countUntil(head," ");
		if(pos<0) // нет доп. значений
		{
			tree.mKey = bell2Space(head);
		}
		else
		{
			tree.mKey = bell2Space(head[0..pos]);
			head = head[pos+1..$];
			// Загрузка доп значений
			int isp;
			while((isp = cast(int)countUntil(head, " ")) > 0)
			{
				string val = bell2Space(head[0..isp]);
				head = head[isp+1..$];
				tree.mVals ~= val;
			}
			tree.mVals ~= bell2Space(head);
		}
		// Распознование тела
		while(!sbody.empty)
		{
			bool sec = false;
			head = strip(getNextElement(sbody, sec));

			if(sec)
			{
				DocNodeTree stree = readSection(head);
				if(stree !is null)
					tree.mSections~=stree;
			} else
			{
				DocNode node = readNode(head);
				if(node !is null)
					tree.mNodes~=node;
			}
		}

		return tree;
	}

	/// Чтение листа
	/**
	*	Откусывается кусок от буфера
	*/
	DocNode readNode(ref string s)
	{
		auto space = countUntil(s, " ");
		DocNode node = new DocNode;
		if(space<0) // без значений
		{
			node.mKey = bell2Space(s);
			return node;
		} else
		{
			auto open = countUntilEscaped(s,"(");
			if(open<0) open = countUntilEscaped(s,"[");
			if(open<0) // только модификаторы и значение
			{
				// Значение
				space = findLastPos(s, 0, " ");
				node.mVals ~= strip(bell2Space(s[space+1..$]));
				s = strip(s[0..space]);
				// Модификаторы и имя
				while((space = countUntil(s," "))>0)
				{
					node.mMods ~= strip(bell2Space(s[0..space]));
					s = s[space+1..$];
				}
				node.mKey=bell2Space(strip(s));
				return node;
			} else
			{
				auto close = findPosEscaped(s, open, ")");
				if(close<0) close = findPosEscaped(s, open, "]");
				if(close<0) // ошибка
					throw new Exception("Invalid count of (/)/[/]!");
				
				auto vals = s[open+1..close];
				s = strip(s[0..open]);

				// Модификаторы
				space = countUntil(s," ");
				while(space>0)
				{	
					node.mMods ~= strip(bell2Space(s[0..space]));
					s = s[space+1..$];
					space = countUntil(s, " ");
				} 
				node.mKey = bell2Space(s);

				// Значения
				space = countUntil(vals, ",");
				while(space >0)
				{
					node.mVals ~= strip(bell2Space(vals[0..space]));
					vals = vals[space+1..$];
					space = countUntil(vals, ",");
				}
				node.mVals ~= strip(bell2Space(vals));
				return node;
			}
		}
	}

	/// Получение позиции закрывающей скобки с учетом вложенности
	sizediff_t getCloseBracket(ref string s)
	{
		size_t counter = 1;
		auto pos = countUntilEscaped(s, "{");
		if(pos<0) return -1;

		size_t i = 1;
		while(counter > 0 && pos+i<s.length)
		{
			if(s[pos+i]=='{' && s[pos+i-1]!='\\') counter++;
			else if(s[pos+i]=='}' && s[pos+i-1]!='\\') counter--;
			if(counter==0) break;
			i++;
		}

		if(pos+i>=s.length) return -1;
		return pos+i;
	}

	/// Получение листа или подсекции
	/**
	*	@par section Сюда записывается true, если прочитанный элемент секция
	*/
	string getNextElement(ref string s, out bool section)
	{
		auto comma 	= getComma(s);
		auto sec 	= countUntilEscaped(s,"{");

		if(sec<0 || comma < sec) // Лист
		{
			if(comma<0)
			{
				string ret = s;
				s = "";
				section = false;
				return ret;
			} else
			{
				string ret = s[0..comma];
				s = strip(s[comma+1..$]);
				section = false;
				return ret;
			}
		} else // Дерево
		{
			sec = getCloseBracket(s);

			string ret = s[0..sec+1];

			if(sec+1 < s.length && s[sec+1]==',')
				if(sec+2 < s.length)
					s = s[sec+2..$];
				else
					s = "";
			else
				s = s[sec+1..$];

			section = true;
			return ret;
		}
	}

	/// Поиск запятой с учетом запятых внутри скобок
	size_t getComma(ref string s)
	{
		bool closed = false;
		bool value = false;
		for(size_t i = 0; i<s.length; i++)
		{
			if(s[i]==',' && !closed && !value)
			{
				return i;
			}
			if(s[i]=='(' || s[i]=='[') closed = true;
			else if(s[i]==')' || s[i]==']') closed = false;

			if(s[i]=='\"') value = !value;
		}
		return -1;
	}

	static char tab 	= cast(char)0x09;
	static char space 	= cast(char)0x20;
	static char endline = cast(char)0x0A;
	static char comma 	= cast(char)0x2C;
	static char openbr 	= cast(char)0x7B;
	static char closebr = cast(char)0x7D;
	static char openbrv = cast(char)0x28;
	static char closebrv= cast(char)0x29;

	/// Запись в файл значения с заданным отступом
	void writeValue(DocNode node, int level = 0)
	{
		static string buff = "static ";
		// табуляция на нужный уровень
		for(int i=0; i<level; i++)
			mFile.write(tab);

		// проверка на ключевые слова
		foreach(mod; node.mods)
			mFile.writeString(mod~" ");

		// вывод названия
		if(!node.key.empty)
		{
			mFile.writeString(node.key);
			if(!node.vals.empty)
				mFile.write(space);
		}

		// вывод нескольких значений
		if(node.vals.length > 1)
		{
			mFile.write(openbrv);
			mFile.write(space);
			foreach(i,val; node.vals)
			{
				mFile.writeString(val);
				if(i != node.vals.length-1)
					mFile.write(comma);
				mFile.write(space);
			}
			mFile.write(closebrv);
		} else if(node.vals.length > 0) // вывод одного значения
		{
			mFile.writeString(node.vals[0]);
		}
		// Закрытие значения запятой
		mFile.write(comma);
		mFile.writeLine("");
	}

	/// Запись заголовка секции
	void writeSectionBegin(DocNodeTree tree, int level = 0)
	{
		// табуляция на нужный уровень
		for(int i=0;i<level;i++)
			mFile.write(tab);

		// название
		mFile.writeString(tree.key);
		mFile.write(space);

		// Значение и если есть до. значение
		foreach(val; tree.vals)
			mFile.writeString(val~" ");

		mFile.writeLine("");
		// табуляция на нужный уровень
		for(int i=0;i<level;i++)
			mFile.write(tab);	
		mFile.write(openbr);
		mFile.writeLine("");
	}

	/// Запись окончание секции
	void writeSectionEnd(DocNodeTree tree, int level = 0)
	{
		// табуляция на нужный уровень
		for(int i=0;i<level;i++)
			mFile.write(tab);

		mFile.write(closebr);
		mFile.writeLine("");
	}

	/// Запись тела секции в файл
	void writeSection(DocNodeTree tree, int level = 0)
	{
		writeSectionBegin(tree, level);

		foreach(node; tree.nodes)
			writeValue(node, level+1);
		foreach(sec; tree.sections)
			writeSection(sec, level+1);

		writeSectionEnd(tree, level);
	}
}

unittest
{
	import std.stdio;

	write("Testing gendoc parser... ");
	scope(success) writeln("Finished!");
	scope(failure) writeln("Failed!");
	
	string testfile = 
`
Section "Val1" 1
{
	Node1,
	Node2 value,
	Node3 [1,2,3],
	Subsection "Val2" 2
	{
		Node3,
	}
}

Section "Val3" Val4
{
	Node4 50,
	Node5 [one, two, thre],
}
`;
	auto stream = new MemoryStream(testfile.dup);
	stream.position = 0;

	auto parser = new DocParser;
	auto tree = parser.parse(stream);

	auto outstream = new MemoryStream();
	parser.write(outstream, tree);
}