// written in the D programming language
/**
*   Copyright: © 2012-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*/
module util.list;

/**
*	Минималистичная реализация односвязного списка.
*/
class List(T)
{
	//static if(is(T : class))
	//	static assert(__traits(compiles, new T();, "Type "~T.strinof~" must have default constructor!");
	
	this()
	{
		mHead = null;
		mLength = 0;
	}
	
	this(T val)
	{
		mHead = new Element(val);
		mLength = mHead.length;
	}
	
	void pushBack(T val)
	{
		if(mHead is null)
		{
			mHead = new Element(val);
			mLength = 1;
		} else
		{
			mHead.pushBack(val);
			mLength = mHead.length;
		}
	}
	
	T popBack()
	{
		if(mHead is null)
			throw new Exception("List is empty!");
			
		if(mHead.next is null)
		{
			auto ret = mHead.value;
			mLength = 0;
			mHead = null;
			return ret;
		} 
		else
		{
			auto ret = mHead.popBack();
			mLength = mHead.length;
			return ret;
		}	
	}
	
	void pushFront(T val)
	{
		if(mHead is null)
		{
			mHead = new Element(val);
			mLength = 1;
		} else
		{
			mHead = mHead.pushFront(val);
			mLength = mHead.length;
		}
	}
	
	T popFront()
	{
		if(mHead is null)
			throw new Exception("List is empty!");
		
		if(mHead.next is null)
		{
			auto ret = mHead.value;
			mLength = 0;
			mHead = null;
			return ret;
		} else
		{
			T ret; 
			mHead = mHead.popFront(ret);
			--mLength;
			return ret;
		}
	}
	
	T front() @property
	{
		if(mHead !is null)
			return mHead.value;
		throw new Exception("List is empty!");	
	}
	
	size_t length() @property
	{
		return mLength;
	}
	
	bool empty() @property
	{
		return mHead is null;
	}
	
	string stringof() @property
	{
		import std.conv;
		
		string ret = "[";
		
		void elRecurse(Element e)
		{
			ret ~= to!string(e.value);
			if(e.next !is null)
			{
				ret ~= ", ";
				elRecurse(e.next);
			}
		}
		
		if(mHead is null)
			return "[]";
			
		elRecurse(mHead);
		return ret~"]";	
	}
	
	private Element mHead;
	private size_t mLength;
	
	private class Element
	{
		this()
		{
			mLength = 1;
		}
		
		/**
		*	Создание списка и инициализирование его значением val.
		*/
		this(T val)
		{
			this();
			mVal = val;
		}
		
		/**
		*	Создание списка и инициализирование его значением val и следующим элементом lnext.
		*/
		this(T val, Element lnext)
		{
			this(val);
			mNext = lnext;
			mLength = 1+lnext.mLength;
		}
		
		/**
		*	Добавляет значение val в конец списка.
		*/
		void pushBack(T val)
		{
			if(mNext !is null)
			{
				mLength += 1;
				mNext.pushBack(val);
			}
			else
			{
				mLength = 2;
				mNext = new Element(val);
			}	
		}
		
		/**
		*	Откусывает значение от конца списка и возращает его.
		*/
		T popBack()
		{
			if(mNext.next !is null)
			{
				mLength -= 1;
				return mNext.popBack();
			}	
			else
			{		
				auto ret = mNext.mVal;
				mNext = null;
				mLength = 0;
				return ret;
			}	
		}
		
		/**
		*	Добавляет значение val в начало списка и возвращает новую голову.
		*/
		Element pushFront(T val)
		{			
			return new Element(val, this);
		}
		
		/**
		*	Откусывает голову списка и возрвращает значение val, новую голову списка.
		*/
		Element popFront(out T val)
		{
			val = mVal;
			return mNext;
		}
		
		/**
		*	Значение, хранимое в голове списка.
		*/
		T value() @property
		{
			return mVal;
		}
		
		/**
		*	Значение, хранимое в голове списка.
		*/	
		void value(T val) @property
		{
			mVal = val;
		}
		
		/**
		*	Следующий элемент списка.
		*/
		Element next() @property
		{
			return mNext;
		}
		
		/**
		*	Длина списка
		*/
		size_t length() @property
		{
			return mLength;
		}
		
		private
		{
			Element mNext;
			T	mVal;
			size_t mLength;
		}
	}
}

unittest
{
	import std.stdio;
	
	auto list = new List!int;
	
	assert(list.empty);
	assert(list.length == 0);
	
	list.pushBack(0);
	assert(list.front == 0);
	assert(list.length == 1);
	assert(!list.empty);
	
	list.pushBack(1);
	assert(list.front == 0);
	assert(list.length == 2);
	assert(!list.empty);
	
	list.pushFront(2);
	assert(list.front == 2);
	assert(list.length == 3);
	assert(!list.empty); 
	
	assert(list.stringof == "[2, 0, 1]");
	auto v = list.popBack();
	assert(v == 1);
	assert(list.length == 2);
	
	v = list.popFront();
	assert(v == 2);
	assert(list.length == 1);
	
	v = list.popFront();
	assert(v == 0);
	assert(list.length == 0);
	assert(list.empty);
}