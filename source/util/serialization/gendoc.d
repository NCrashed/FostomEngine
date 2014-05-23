// written in the D programming language
/**
*   Copyright: © 2012-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*	Modules provides backend sealization for 'General Document' file format. It is human-readable format for tree structure serialization.
*
*	See_Also: 
*		util.parser util.serialization.serializer
*
*	Authors:
*		Gushcha Anton (NCrashed)
*/
module util.serialization.gendoc;

import util.serialization.serializer;
import std.stream;
import std.exception;
import std.conv;
import util.parser;

/// Backend archive generator
class GendocArchive
{
public:

	this()
	{
		mTree = new DocNodeTree;
		mPlaces = new DocNodeTree[1];
		mPlaces[0] = mTree;
	}

	mixin ArchiveGenerator;

	/**
	*	Retrives place descriptor of tree root. It is first place to write accessible after acrhvie initialization.
	*/
	PlaceId getRootPlace()
	{
		return 0;
	}

	/**
	*	Writes down all accumulated information in memory stream. This operation occurs after all data loaded in backend generator.
	*/
	Stream 	writeStream()
	{
		auto stream = new MemoryStream;
		auto parser = new DocParser;

		parser.write(stream, mTree);

		return stream;
	}

	/**
	*	Writes down all accumulated information in a file with $(B name). This operation occurs after all data loaded in backend generator.
	*/
	void writeFile(string name)
	{
		auto stream = new std.stream.File(name, FileMode.OutNew);
		auto parser = new DocParser;

		parser.write(stream, mTree);

		stream.close();
	}

	/**
	*	Reads all information for deserialization from $(B stream). This operation occurs befor all data reading operations.
	*/
	void readStream(Stream stream)
	{
		auto parser = new DocParser;
		mTree = parser.parse(stream);
		mPlaces[0] = mTree;
		mArrayPlaces[0] = false;
	}

	/**
	*	Reads all information for deserialization from file $(B name). This operation occurs befor all data reading operations.
	*/
	void readFile(string name)
	{
		auto stream = new std.stream.File(name, FileMode.In);
		auto parser = new DocParser;

		mTree = parser.parse(stream);
		mPlaces[0] = mTree;
		mArrayPlaces[0] = false;
		
		stream.close();
	}

private:
	DocNodeTree 		mTree;
	DocNodeTree[] 		mPlaces;
	bool[PlaceId]		mArrayPlaces;
	
	// checks place descriptor to be correct
	bool checkPlace(PlaceId id)
	{
		return id >= 0 && id < mPlaces.length;
	}

	// checks if place is aggregate array
	bool isAggregateArray(PlaceId id)
	{
		return checkPlace(id) && mArrayPlaces[id];
	}
	
	enum PLACE_ERROR_MSG = "Passed wrong PlaceId!";
	enum PLACE_ARRAY_ERROR_MSG = "Passed place isn't aggregate array!";
	
	enum CLASS_KEY = "Class";
	enum STRUCT_KEY = "Struct";
	enum MAP_KEY = "Map";
	enum CLASS_ARRAY_KEY = "ClassArray";
	enum STRUCT_ARRAY_KEY = "StructArray";
	
	// United method to allocate place for structs and classes
	PlaceId writeSection(Class)(PlaceId parent, string name, string key)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		DocNodeTree ptree = mPlaces[parent];

		DocNodeTree tree = new DocNodeTree;
		
		tree.key = key;
		tree.addVal(Class.stringof);
		tree.addVal(name);
		ptree.addSubSection(tree);

		PlaceId ret = mPlaces.length;
		mPlaces ~= tree;
		mArrayPlaces[ret] = false;
		
		return ret;
	}

	/*
	*	If string $(B s) has dangerous symbols for file parsing, wraps it with quotes.
	*/
	string escapeChars(string s)
	{
		if( countUntil(s, "[") > 0 || countUntil(s, "]") > 0 || countUntil(s, "(") >0 || countUntil(s, ")") > 0)
			return `"`~s~`"`;
		return s;
	}

protected:

	/**
	*	Adds $(B Class) to archive at place $(B parent) with $(B name). This method should only prepare new place for data and return $(B PlaceId).
	*	All actual data will be passed throught $(B writePlainField), $(B writeArray), $(B writeAssociativeArray), but class instance $(B val) passes to method 
	*	for some meta-data records. Seperate interfaces for classes and structs helps seperate serialization semantic, although inner backend implementation can
	*	write classes and structs with single algorithm.
	*/
	PlaceId writeClass(Class)(PlaceId parent, string name, Class val)
	{
		return writeSection!Class(parent, name, CLASS_KEY);
	}

	/**
	*	Adds $(B Struct) to archive at place $(B parent) with $(B name). This method should only prepare new place for data and return $(B PlaceId).
	*	All actual data will be passed throught $(B writePlainField), $(B writeArray), $(B writeAssociativeArray), but struct instance $(B val) passes to method 
	*	for some meta-data records. Seperate interfaces for classes and structs helps seperate serialization semantic, although inner backend implementation can
	*	write classes and structs with single algorithm.
	*/
	PlaceId writeStruct(Struct)(PlaceId parent, string name, Struct val)
	{
		return writeSection!Struct(parent, name, STRUCT_KEY);
	}

	/**
	*	Adds array of $(B Element) to archive at place $(B parent) with name $(B name). This method should only prepare new place for data 
	*	and return $(B PlaceId).
	*/
	PlaceId writeClassArray(Element)(PlaceId parent, string name, Element[] val)
	{
		auto ret = writeSection!Element(parent, name, CLASS_ARRAY_KEY);
		mArrayPlaces[ret] = true;
		return ret;
	}

	/**
	*	Adds array of $(B Element) to archive at place $(B parent) with name $(B name). This method should only prepare new place for data 
	*	and return $(B PlaceId).
	*/
	PlaceId writeStructArray(Element)(PlaceId parent, string name, Element[] val)
	{
		auto ret = writeSection!Element(parent, name, STRUCT_ARRAY_KEY);
		mArrayPlaces[ret] = true;
		return ret;
	}

	/**
	*	Retrives place descriptor of $(B Element) class array with $(B name) from place $(B parent). If cannot find, should throw ReadValueException.
	*/
	size_t getClassArraySize(Element)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		DocNodeTree ptree = mPlaces[parent];

		DocNodeTree tree = ptree.subSection(CLASS_ARRAY_KEY, Element.stringof, name);
		if(tree is null)
			throw new ReadValueException!Element(parent, name, "Cannot find class array '"~Element.stringof~"[]' '"~name~"' at place "~to!string(parent)~"!");
		
		size_t ret = 0;
		foreach(sec; tree.sections)
		{
			if(sec.key == CLASS_KEY && sec.vals.length >= 2 && sec.vals[0] == Element.stringof)
				++ret;
		}
		return ret;
	}

	/**
	*	Retrives place descriptor of $(B Element) struct array with $(B name) from place $(B parent). If cannot find, should throw ReadValueException.
	*/
	size_t getStructArraySize(Element)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		DocNodeTree ptree = mPlaces[parent];

		DocNodeTree tree = ptree.subSection(STRUCT_ARRAY_KEY, Element.stringof, name);
		if(tree is null)
			throw new ReadValueException!Element(parent, name, "Cannot find struct array '"~Element.stringof~"[]' '"~name~"' at place "~to!string(parent)~"!");
		
		size_t ret = 0;
		foreach(sec; tree.sections)
		{
			if(sec.key == STRUCT_KEY && sec.vals.length >= 2 && sec.vals[0] == Element.stringof)
				++ret;
		}
		return ret;
	}
	
	/**
	*	Adds $(B Type) POD field to archive at place $(B parent) with $(B name).
	*/
	void writePlainField(Type)(PlaceId parent, string name, Type val)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		DocNodeTree tree = mPlaces[parent];		

		auto node = new DocNode;
		node.addMod(escapeChars(Type.stringof));
		node.key = name;
		
		try
		{
			node.addVal(to!string(val));
		}
		catch(Exception e)
		{
			throw new Exception("Type "~Type.stringof~" cannot be converted to string!");
		}
		tree.addNode(node);
	}

	/**
	*	Adds $(B Type) array of POD data to archive at place $(B parent) with $(B name). Currently array of objects or structs doesn't work correct.
	*/
	void writeArray(Type)(PlaceId parent, string name, Type val)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		DocNodeTree tree = mPlaces[parent];		

		auto node = new DocNode;
		node.addMod(escapeChars(Type.stringof));
		node.key = name;

		try
		{	
			static if(is(Type == string))
			{
				node.addVal(`"`~val~`"`);
			} 
			else
			{
				foreach(v; val)
					node.addVal(to!string(v));
			}
		}
		catch(Exception e)
		{
			throw new Exception("Type "~Type.stringof~" cannot be converted to string!");
		}	
		tree.addNode(node);	
	}

	/**
	*	Adds $(B Type) associative array of POD data to archive at place $(B parent) with $(B name). Currently array of objects or structs 
	*	doesn't work correct.
	*/
	void writeAssociativeArray(Type)(PlaceId parent, string name, Type val)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		DocNodeTree ptree = mPlaces[parent];

		DocNodeTree tree = new DocNodeTree;
		tree.key = MAP_KEY;
		tree.addVal(escapeChars(Type.stringof));
		tree.addVal(name);

		try
		{	
			foreach(k,v; val)
			{
				auto node = new DocNode;
				node.key = to!string(k);
				node.addVal(to!string(v));
				tree.addNode(node);
			}
		}
		catch(Exception e)
		{
			throw new Exception("Type "~Type.stringof~" cannot be converted to string!");
		}	
		ptree.addSubSection(tree);
	}

	/**
	*	Checks existance of $(B Class) at place $(B parent). Returns true if exists, false else. 
	*/
	bool isClassExists(Class)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		DocNodeTree ptree = mPlaces[parent];
		
		auto ret = ptree.subSection(CLASS_KEY, Class.stringof, name);

		return ret !is null;
	}

	/**
	*	Checks existance of $(B Struct) at place $(B parent). Returns true if exists, false else.
	*/
	bool isStructExists(Struct)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		DocNodeTree ptree = mPlaces[parent];

		auto ret = ptree.subSection(STRUCT_KEY, Struct.stringof, name);		
	
		return ret !is null;
	}

	/**
	*	Checks existance of class array field with element $(B Element) at place $(B parent). Returns true if exists, false else.
	*/
	bool isClassArrayExists(Element)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		DocNodeTree ptree = mPlaces[parent];

		DocNodeTree tree = ptree.subSection(CLASS_ARRAY_KEY, Element.stringof, name);
		return tree !is null;
	}

	/**
	*	Checks existance of struct array field with element $(B Element) at place $(B parent). Returns true if exists, false else.
	*/
	bool isStructArrayExists(Element)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		DocNodeTree ptree = mPlaces[parent];

		DocNodeTree tree = ptree.subSection(STRUCT_ARRAY_KEY, Element.stringof, name);
		return tree !is null;
	}
	
	/**
	*	Checks existance of POD field $(B Type) at place $(B parent). Returns true if exists, false else.
	*/
	bool isPlainFieldExists(Type)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		DocNodeTree tree = mPlaces[parent];

		DocNode ret = tree.getNode(name);
		return ret !is null && ret.getMod(0) == Type.stringof;
	}

	/**
	*	Checks existance of POD array data field $(B Type) at place $(B parent). Returns true if exists, false else.
	*/
	bool isArrayExists(Type)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		DocNodeTree tree = mPlaces[parent];

		auto ret = tree.getNode(name);
		return ret !is null && ret.getMod(0) == Type.stringof;
	}

	/**
	*	Checks existance of POD associative array data field $(B Type) at place $(B parent). Returns true if exists, false else.
	*/
	bool isAssociativeArrayExists(Type)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		DocNodeTree tree = mPlaces[parent];

		auto ret = tree.subSection(MAP_KEY, Type.stringof, name);
		return ret !is null;
	}

	/**
	*	Retrives place descriptor of $(B Struct) with $(B name) from place $(B parent). If cannot find, throws ReadValueException.
	*/
	PlaceId getStructPlace(Struct)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		DocNodeTree tree = mPlaces[parent];

		auto ret = tree.subSection(STRUCT_KEY, Struct.stringof, name);
		if(ret is null)
			throw new ReadValueException!Struct(parent, name, "Cannot find struct '"~Struct.stringof~"' '"~name~"' at place "~to!string(parent)~"!");

		foreach(i, place; mPlaces)
			if(place == ret)		
				return i;
		
		mPlaces ~= ret;
		mArrayPlaces[mPlaces.length-1] = false;
		return mPlaces.length-1;
	}

	/**
	*	Retrives place descriptor of $(B Class) with $(B name) from place $(B parent). If cannot find, throws ReadValueException.
	*/
	PlaceId getClassPlace(Class)(PlaceId parent, string name)
	{	
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		DocNodeTree tree = mPlaces[parent];

		auto ret = tree.subSection(CLASS_KEY, Class.stringof, name);
		if(ret is null)
			throw new ReadValueException!Class(parent, name, "Cannot find class '"~Class.stringof~"' '"~name~"' at place "~to!string(parent)~"!");

		foreach(i, place; mPlaces)
			if(place == ret)		
				return i;

		mPlaces ~= ret;
		mArrayPlaces[mPlaces.length-1] = false;
		return mPlaces.length-1;
	}

	/**
	*	Retrives place descriptor of $(B Element) class array with $(B name) from place $(B parent). If cannot find, should throw ReadValueException.
	*/
	PlaceId getClassArrayPlace(Element)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		DocNodeTree ptree = mPlaces[parent];

		DocNodeTree tree = ptree.subSection(CLASS_ARRAY_KEY, Element.stringof, name);
		if(tree is null)
			throw new ReadValueException!Element(parent, name, "Cannot find class array '"~Element.stringof~"[]' '"~name~"' at place "~to!string(parent)~"!");

		foreach(i, place; mPlaces)
			if(place == tree)		
				return i;

		mPlaces ~= tree;
		mArrayPlaces[mPlaces.length-1] = true;
		return mPlaces.length-1;		
	}

	/**
	*	Retrives place descriptor of $(B Element) struct array with $(B name) from place $(B parent). If cannot find, should throw ReadValueException.
	*/
	PlaceId getStructArrayPlace(Element)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		DocNodeTree ptree = mPlaces[parent];

		DocNodeTree tree = ptree.subSection(STRUCT_ARRAY_KEY, Element.stringof, name);
		if(tree is null)
			throw new ReadValueException!Element(parent, name, "Cannot find struct array '"~Element.stringof~"[]' '"~name~"' at place "~to!string(parent)~"!");

		foreach(i, place; mPlaces)
			if(place == tree)		
				return i;

		mPlaces ~= tree;
		mArrayPlaces[mPlaces.length-1] = true;
		return mPlaces.length-1;	
	}
	
	/**
	*	Gets $(B Type) array of POD data from archive at place $(B parent) with $(B name). Currently array of objects/structs doesn't work correct.
	*/
	Type readArray(Type)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		DocNodeTree tree = mPlaces[parent];

		auto node = tree.getNode(name);
		assert(node !is null, "Getted node is null! Recheck frontend!");
		assert(Type.stringof == node.getMod(0), "Getted type isn't "~Type.stringof~", but "~node.getMod(0));

		alias ArrayElementType!Type Element;

		static if(is(Type == string))
			string ret;
		else
			auto ret = new Element[node.vals.length];

		try
		{	
			static if(is(Type == string))
			{
				ret = node.getVal!string(0);
			} 
			else
			{ 
				foreach(size_t i; 0..node.vals.length)
					ret[i] = node.getVal!Element(i);
			}
		}
		catch(Exception e)
		{
			throw new ReadValueException!Type(parent, name, "Type "~Element.stringof~" cannot be converted back from string!");
		}	
		return ret;
	}

	/**
	*	Gets $(B Type) associatvie array of POD data from archive at place $(B parent) with $(B name). Currently array of objects/structs
	*	doesn't work correct.
	*/
	Type readAssociativeArray(Type)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		DocNodeTree tree = mPlaces[parent];

		auto sec = tree.subSection(MAP_KEY, Type.stringof, name);		
		assert(sec !is null, "Getted map is null! Recheck frontend!");

		Type map;

		foreach(node; sec.nodes)
		{
			try
			{
				map[to!(AssociativeArrayKeyType!Type)(node.key)] = to!(AssociativeArrayValueType!Type)(node.getVal!string(0));
			} 
			catch(Exception e)
			{
				throw new ReadValueException!Type(parent, name, "Failed to deseialize map!");
			}
		}
		return map;
	}

	/**
	*	Gets $(B Type) POD field from archive at place $(B parent) with $(B name).
	*/
	Type readPlainField(Type)(PlaceId parent, string name)
	{
		enforce(checkPlace(parent), PLACE_ERROR_MSG);
		DocNodeTree tree = mPlaces[parent];

		auto node = tree.getNode(name);
		assert(node !is null, "Getted node is null! Recheck frontend!");
		assert(Type.stringof == node.getMod(0), "Getted type isn't "~Type.stringof~", but "~node.getMod(0));

		Type ret;

		try
		{
			ret = to!Type(node.getVal!string(0));
		}	
		catch(Exception e)
		{
			throw new ReadValueException!Type(parent, name, "Failed to deserialize field!");
		}	
		return ret;
	}

}