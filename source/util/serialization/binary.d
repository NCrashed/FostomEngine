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
*	Modules provides backend sealization for simple binary representation. It used at net transfer protocol for messages.
*
*	See_Also: 
*		util.serialization.serializer
*
*	Authors:
*/
module util.serialization.binary;


import util.serialization.serializer;
import std.stream;
import std.exception;
import std.conv;
import std.traits;
import util.common;

import std.stdio;
import std.zlib;

enum COMPRESS_LEVEL = 4;

private enum STORAGE_TYPE: uint
{
	CLASS = 0u,
	STRUCT = 1u,
	CLASS_ARRAY = 2u,
	STRUCT_ARRAY = 3u,
}

private enum FIELD_TYPE: uint
{
	POD = 0u,
	ARRAY = 1u,
	ASSOCIATIVE_ARRAY = 2u,
}

private class AggregateTree
{
	string name;
	AggregateTree[] aggregates;

	struct Field
	{
		string name;
		Stream data;

		FIELD_TYPE type;

		this(string pname)
		{
			name = pname;
			data = new MemoryStream;
		}
		
		void writePOD(T)(T val)
		{
			type = FIELD_TYPE.POD;
			data.writeExact(cast(void*)&val, T.sizeof);
			data.position = 0;
		}

		void writeArray(T)(T[] val)
		{
			type = FIELD_TYPE.ARRAY;
			data.writeExact(val.ptr, T.sizeof*val.length);
			data.position = 0;
		}

		void writeAssociativeArray(T,U)(T[U] val)
		{
			type = FIELD_TYPE.ASSOCIATIVE_ARRAY;
			auto keys = new U[0];
			auto vals = new T[0];
			foreach(k,v; val)
			{
				keys ~= k;
				vals ~= v;
			}

			ulong size = cast(ulong)val.length;
			data.write(size);

			static if(is(U K1: K1[]))
			{
				foreach(k; keys)
				{
					size = cast(ulong)k.length;
					data.write(size);
					data.writeExact(k.ptr, cast(size_t)K1.sizeof*k.length);
				}
			} else
				data.writeExact(keys.ptr, U.sizeof*keys.length);
				
			static if(is(T K2: K2[]))
			{
				foreach(v; vals)
				{
					size = cast(ulong)v.length;
					data.write(size);
					data.writeExact(v.ptr, cast(size_t)K2.sizeof*v.length);
				}
			} else
				data.writeExact(vals.ptr, cast(size_t)T.sizeof*vals.length);
			

			data.position = 0;
		}

		T getPOD(T)()
		{
			assert(type == FIELD_TYPE.POD);
			T ret;
			data.readExact(cast(void*)&ret, T.sizeof);
			data.position = 0;
			return ret;
		}

		T[] getArray(T)()
		{
			
			assert(type == FIELD_TYPE.ARRAY);
			auto ret = new T[0];
			while(!data.eof)
			{
				Unqual!T temp;
				data.readExact(cast(void*)&temp, T.sizeof);
				ret ~= temp;
			}
			data.position = 0;
			
			return ret;
		}

		T[U] getAssociativeArray(T,U)()
		{
			assert(type == FIELD_TYPE.ASSOCIATIVE_ARRAY);
	
			ulong size;
			data.read(size);
	
			auto keys = new U[cast(size_t)size];
			auto vals = new T[cast(size_t)size];

			for(ulong i = 0; i<keys.length; i++)
			{
				static if(is(U K: K[]))
				{
					data.read(size);
					keys[cast(size_t)i] = new K[cast(size_t)size];
					data.readExact(cast(void*)keys[cast(size_t)i].ptr, cast(size_t)size*K.sizeof);
				}
				else
					data.readExact(cast(void*)keys[cast(size_t)i].ptr, U.sizeof);
			}
			for(ulong i = 0; i<vals.length; i++)
			{
				static if(is(T K: K[]))
				{
					data.read(size);
					vals[cast(size_t)i] = new K[cast(size_t)size];
					data.readExact(cast(void*)vals[cast(size_t)i].ptr, cast(size_t)size*K.sizeof);
				}
				else
					data.readExact(cast(void*)vals[cast(size_t)i].ptr, T.sizeof);
			}

			T[U] map;
			foreach(i, key; keys)
				map[key] = vals[i];

			return map;
		}
	}
	Field[] fields;
	STORAGE_TYPE type;
	
	this()
	{
		aggregates = new AggregateTree[0];
		fields = new Field[0];
	}

	this(string pname)
	{
		this();
		name = pname;
	}
}

class BinaryArchive 
{
	mixin ArchiveGenerator;

public:

	this()
	{
		mPlaces = new AggregateTree[1];
		mPlaces[0] = new AggregateTree;
		mPlaces[0].name = "Root";
		mPlaces[0].type = STORAGE_TYPE.CLASS;
	}

	PlaceId getRootPlace()
	{
		return 0;
	}

	Stream writeStream()
	{
		auto stream = new MemoryStream;

		writeNode(mPlaces[0], stream);
		stream.position = 0;
		
		auto data = new ubyte[cast(size_t)stream.size];
		stream.read(data);
		
		auto cdata = cast(ubyte[])compress(cast(void[]) data, COMPRESS_LEVEL);
		return new MemoryStream(cdata);
	}
	
	void writeFile(string name)
	{
		auto file = new std.stream.File(name, FileMode.OutNew);

		auto stream = writeStream();
		auto data = new ubyte[cast(size_t)stream.size];
		stream.read(data);
		
		file.write(data);
		file.close();
	}

	void readStream(Stream stream)
	{
		stream.position = 0;

		auto data = new ubyte[cast(size_t)stream.size];
		stream.read(data);

		auto cdata = cast(ubyte[])uncompress(cast(void[]) data);
		mPlaces[0] = readNode(new MemoryStream(cdata));
	}

	void readFile(string name)
	{
		auto file = new std.stream.File(name, FileMode.In);

		readStream(file);
	}

private:
	AggregateTree[] mPlaces;

	// checks place descriptor to be correct
	bool checkPlace(PlaceId id)
	{
		return id >= 0 && id < mPlaces.length;
	}

	void writeNode(AggregateTree node, Stream stream)
	{

		//writing name
		stream.write(cast(ulong)node.name.length);
		stream.writeExact(node.name.ptr, cast(size_t)char.sizeof*node.name.length);

		//writing type
		stream.write(cast(uint)node.type);

		//writing fields count
		stream.write(cast(ulong)node.fields.length);

		//writing fields
		foreach(f; node.fields)
		{
			//writing field name
			stream.write(cast(ulong)f.name.length);
			stream.writeExact(f.name.ptr, cast(size_t)char.sizeof*f.name.length);

			//writing field type
			stream.write(cast(uint)f.type);

			//writing field size and data
			stream.write(cast(ulong)f.data.size);
			stream.copyFrom(f.data);
		}

		//writing aggregates count
		stream.write(cast(ulong)node.aggregates.length);

		//writing aggregates
		foreach(a; node.aggregates)
			writeNode(a, stream);
	}

	AggregateTree readNode(Stream stream)
	{
		auto ret = new AggregateTree();

		// reading name
		ulong size;
		stream.read(size);
		auto cname = new char[cast(size_t)size];

		stream.readExact(cname.ptr, cast(size_t)size*char.sizeof);
		ret.name = cname.idup;

		// reading type
		uint type;
		stream.read(type);
		ret.type = cast(STORAGE_TYPE)type;

		// reading fields count
		stream.read(size);
		ret.fields = new AggregateTree.Field[cast(size_t)size];
	
		// reading fields
		foreach(ref f; ret.fields)
		{
			//reading name
			stream.read(size);
			auto bname = new char[cast(size_t)size];

			stream.readExact(bname.ptr, cast(size_t)size*char.sizeof);
			f.name = bname.idup;	

			//reading type
			stream.read(type);
			f.type = cast(FIELD_TYPE)type;

			//reading data size and data
			stream.read(size);

			f.data = new MemoryStream;
			f.data.copyFrom(stream, size);
			f.data.position = 0;
		}

		//reading aggregates count and aggregates
		stream.read(size);
		ret.aggregates = new AggregateTree[cast(size_t)size];

		foreach(ref a; ret.aggregates)
			a = readNode(stream);

		return ret;
	}
		
	PlaceId addNode(PlaceId parent, string name, STORAGE_TYPE type)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		auto node = new AggregateTree(name);
		node.type = type;

		auto pnode = mPlaces[parent];
		pnode.aggregates ~= node;
		mPlaces ~= node;
		return mPlaces.length-1;
	}

	bool checkNode(PlaceId parent, string name, STORAGE_TYPE type)
	{
		auto pnode = mPlaces[parent];

		foreach(a; pnode.aggregates)
			if(a.type == type && a.name == name)
				return true;
		return false;
	}

	bool checkField(PlaceId parent, string name, FIELD_TYPE type)
	{
		auto pnode = mPlaces[parent];

		foreach(a; pnode.fields)
			if(a.type == type && a.name == name)
				return true;
		return false;		
	}

	PlaceId getNodePlace(T)(PlaceId parent, string name, STORAGE_TYPE type)
	{
		auto pnode = mPlaces[parent];
		AggregateTree node;
		foreach(a; pnode.aggregates)
			if(a.type == type && a.name == name)
			{
				node = a;
				break;
			}

		if(node is null)
			throw new ReadValueException!T(parent, name, text("Cannot find ",T.stringof," with name ",name," at place ", parent));

		foreach(i,place; mPlaces)
			if(place == node)
				return i;

		mPlaces ~= node;
		return mPlaces.length-1;
	}

	enum PLACE_ERROR_MSG = "Passed wrong PlaceId!";
	enum PLACE_ARRAY_ERROR_MSG = "Passed place isn't aggregate array!";
protected:

	/**
	*	Adds $(B Class) to archive at place $(B parent) with $(B name). This method should only prepare new place for data and return $(B PlaceId).
	*	All actual data will be passed throught $(B writePlainField), $(B writeArray), $(B writeAssociativeArray), but class instance $(B val) passes to method 
	*	for some meta-data records. Seperate interfaces for classes and structs helps seperate serialization semantic, although inner backend implementation can
	*	write classes and structs with single algorithm.
	*/
	PlaceId writeClass(Class)(PlaceId parent, string name, Class val)
	{
		return addNode(parent, name, STORAGE_TYPE.CLASS);
	}

	/**
	*	Adds $(B Struct) to archive at place $(B parent) with $(B name). This method should only prepare new place for data and return $(B PlaceId).
	*	All actual data will be passed throught $(B writePlainField), $(B writeArray), $(B writeAssociativeArray), but struct instance $(B val) passes to method 
	*	for some meta-data records. Seperate interfaces for classes and structs helps seperate serialization semantic, although inner backend implementation can
	*	write classes and structs with single algorithm.
	*/
	PlaceId writeStruct(Struct)(PlaceId parent, string name, Struct val)
	{
		return addNode(parent, name, STORAGE_TYPE.STRUCT);	
	}

	/**
	*	Adds array of $(B Element) to archive at place $(B parent) with name $(B name). This method should only prepare new place for data 
	*	and return $(B PlaceId).
	*/
	PlaceId writeClassArray(Element)(PlaceId parent, string name, Element[] val)
	{
		return addNode(parent, name, STORAGE_TYPE.CLASS_ARRAY);
	}

	/**
	*	Adds array of $(B Element) to archive at place $(B parent) with name $(B name). This method should only prepare new place for data 
	*	and return $(B PlaceId).
	*/
	PlaceId writeStructArray(Element)(PlaceId parent, string name, Element[] val)
	{
		return addNode(parent, name, STORAGE_TYPE.STRUCT_ARRAY);
	}

	/**
	*	Retrives place descriptor of $(B Element) class array with $(B name) from place $(B parent). If cannot find, should throw ReadValueException.
	*/
	size_t getClassArraySize(Element)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		auto pnode = mPlaces[parent];

		foreach(a; pnode.aggregates)
			if( a.type == STORAGE_TYPE.CLASS_ARRAY && a.name == name)
				return a.aggregates.length;

		throw new ReadValueException!Element(parent, name, text("Cannot find class array ",Element.stringof,"[] with name ",name," at place ", parent));
	}

	/**
	*	Retrives place descriptor of $(B Element) struct array with $(B name) from place $(B parent). If cannot find, should throw ReadValueException.
	*/
	size_t getStructArraySize(Element)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		auto pnode = mPlaces[parent];

		foreach(a; pnode.aggregates)
			if( a.type == STORAGE_TYPE.STRUCT_ARRAY && a.name == name)
				return a.aggregates.length;

		throw new ReadValueException!Element(parent, name, text("Cannot find struct array ",Element.stringof,"[] with name ",name," at place ", parent));
	}
	
	/**
	*	Adds $(B Type) POD field to archive at place $(B parent) with $(B name).
	*/
	void writePlainField(Type)(PlaceId parent, string name, Type val)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		auto pnode = mPlaces[parent];

		auto field = AggregateTree.Field(name);
		field.writePOD!Type(val);

		pnode.fields ~= field;
	}

	/**
	*	Adds $(B Type) array of POD data to archive at place $(B parent) with $(B name).
	*/
	void writeArray(Type)(PlaceId parent, string name, Type val)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		auto pnode = mPlaces[parent];

		auto field = AggregateTree.Field(name);
		field.writeArray!(ArrayElementType!Type)(val);

		pnode.fields ~= field;
	}

	/**
	*	Adds $(B Type) associative array of POD data to archive at place $(B parent) with $(B name).
	*/
	void writeAssociativeArray(Type)(PlaceId parent, string name, Type val)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		auto pnode = mPlaces[parent];

		auto field = AggregateTree.Field(name);
		field.writeAssociativeArray!(AssociativeArrayValueType!Type, AssociativeArrayKeyType!Type)(val);

		pnode.fields ~= field;
	}

	/**
	*	Checks existance of $(B Class) at place $(B parent). Returns true if exists, false else. 
	*/
	bool isClassExists(Class)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		return checkNode(parent, name, STORAGE_TYPE.CLASS);
	}

	/**
	*	Checks existance of $(B Struct) at place $(B parent). Returns true if exists, false else.
	*/
	bool isStructExists(Struct)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		return checkNode(parent, name, STORAGE_TYPE.STRUCT);
	}

	/**
	*	Checks existance of class array field with element $(B Element) at place $(B parent). Returns true if exists, false else.
	*/
	bool isClassArrayExists(Element)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		return checkNode(parent, name, STORAGE_TYPE.CLASS_ARRAY);
	}

	/**
	*	Checks existance of struct array field with element $(B Element) at place $(B parent). Returns true if exists, false else.
	*/
	bool isStructArrayExists(Element)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		return checkNode(parent, name, STORAGE_TYPE.STRUCT_ARRAY);
	}
	
	/**
	*	Checks existance of POD field $(B Type) at place $(B parent). Returns true if exists, false else.
	*/
	bool isPlainFieldExists(Type)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		return checkField(parent, name, FIELD_TYPE.POD);
	}

	/**
	*	Checks existance of POD array data field $(B Type) at place $(B parent). Returns true if exists, false else.
	*/
	bool isArrayExists(Type)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		return checkField(parent, name, FIELD_TYPE.ARRAY);
	}

	/**
	*	Checks existance of POD associative array data field $(B Type) at place $(B parent). Returns true if exists, false else.
	*/
	bool isAssociativeArrayExists(Type)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		return checkField(parent, name, FIELD_TYPE.ASSOCIATIVE_ARRAY);
	}

	/**
	*	Retrives place descriptor of $(B Struct) with $(B name) from place $(B parent). If cannot find, throws ReadValueException.
	*/
	PlaceId getStructPlace(Struct)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		return getNodePlace!Struct(parent, name, STORAGE_TYPE.STRUCT);
	}

	/**
	*	Retrives place descriptor of $(B Class) with $(B name) from place $(B parent). If cannot find, throws ReadValueException.
	*/
	PlaceId getClassPlace(Class)(PlaceId parent, string name)
	{	
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		return getNodePlace!Class(parent, name, STORAGE_TYPE.CLASS);
	}

	/**
	*	Retrives place descriptor of $(B Element) class array with $(B name) from place $(B parent). If cannot find, should throw ReadValueException.
	*/
	PlaceId getClassArrayPlace(Element)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		return getNodePlace!Element(parent, name, STORAGE_TYPE.CLASS_ARRAY);
	}

	/**
	*	Retrives place descriptor of $(B Element) struct array with $(B name) from place $(B parent). If cannot find, should throw ReadValueException.
	*/
	PlaceId getStructArrayPlace(Element)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		return getNodePlace!Element(parent, name, STORAGE_TYPE.STRUCT_ARRAY);
	}
	
	/**
	*	Gets $(B Type) array of POD data from archive at place $(B parent) with $(B name). Currently array of objects/structs doesn't work correct.
	*/
	Type readArray(Type)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);

		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		auto pnode = mPlaces[parent];

		foreach(f; pnode.fields)
			if(f.type == FIELD_TYPE.ARRAY && f.name == name)
				return f.getArray!(ArrayElementType!Type)();

		throw new ReadValueException!Type(parent, name, text("Cannot find ",Type.stringof," with name ",name," at place ", parent));
	}

	/**
	*	Gets $(B Type) associatvie array of POD data from archive at place $(B parent) with $(B name). Currently array of objects/structs
	*	doesn't work correct.
	*/
	Type readAssociativeArray(Type)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		auto pnode = mPlaces[parent];

		foreach(f; pnode.fields)
			if(f.type == FIELD_TYPE.ASSOCIATIVE_ARRAY && f.name == name)
				return f.getAssociativeArray!(AssociativeArrayValueType!Type, AssociativeArrayKeyType!Type)();

		throw new ReadValueException!Type(parent, name, text("Cannot find ",Type.stringof," with name ",name," at place ", parent));
	}

	/**
	*	Gets $(B Type) POD field from archive at place $(B parent) with $(B name).
	*/
	Type readPlainField(Type)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		auto pnode = mPlaces[parent];

		foreach(f; pnode.fields)
			if(f.type == FIELD_TYPE.POD && f.name == name)
				return f.getPOD!Type();

		throw new ReadValueException!Type(parent, name, text("Cannot find ",Type.stringof," with name ",name," at place ", parent));
	}
}