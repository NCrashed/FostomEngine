// written in the D programming language
/**
*   Copyright: © 2012-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*	Module provides frontend for aggregate type serialization and interfaces for actual backends, adds helpfull tools to simplify serialization for users
*	and developers.
*
*	Example:
*	---------
*	class B
*	{
*		string d = "some string";
*
*		string[string] someMap;
*
*		this()
*		{
*			someMap = ["key1":"value1", "key2":"value2", "key3":"value3"];
*		}
*	}
*
*	class A
*	{
*		int a = 1;
*		bool b = true;
*		string c = "another string";
*		B mB;
*
*		this()
*		{
*			mB = new B();
*		}
*	}
*
*	A test = new A;
*
*	auto stream = serialize!GendocArchive(test, "someTestClass");
*	stream.position = 0;
*	auto c = deserialize!(GendocArchive, A)(stream, "someTestClass");
*
*	assert(c.a == 1);
*	assert(c.b);
*	assert(c.c == "another string");
*	assert(c.mB.d == "some string");
*	assert(c.mB.someMap == ["key1":"value1", "key2":"value2", "key3":"value3"]);
*
*	serialize!GendocArchive(test, "someTestClass", "test.txt");
*	c = deserialize!(GendocArchive, A)("test.txt", "someTestClass");
*
*	assert(c.a == 1);
*	assert(c.b);
*	assert(c.c == "another string");
*	assert(c.mB.d == "some string");
*	assert(c.mB.someMap == ["key1":"value1", "key2":"value2", "key3":"value3"]);
*	---------
*
*	Authors: Gushcha Anton (NCrashed)
*	Version: 1.1
*/
module util.serialization.serializer;

import std.traits;
import std.typetuple;
import util.common;

public
{
	import util.serialization.gendoc;
	import util.serialization.binary;

	import std.stream;
}

/// CheckTreeExpanding
/**
*	Checks if class/struct/union can be serialized without infinite recursive expanding. Returns $(D true), if $(Aggregate) can be
*	presented by a tree, and $(D false), if it has cross reference.
*
*	Example:
*	-----------
*	class A
*	{
*		bool a;
*		string b;
*
*		class B
*		{
*			bool val;
*		}
*		class C
*		{
*			B mB;
*		}
*
*		B mB;
*	}
*	static assert(CheckTreeExpanding!A);
*
*	class S2
*	{
*		class A
*		{
*			C mC;
*		}
*		class B
*		{
*			A mA;
*		}
*		class C
*		{
*			B mB;
*		}
*		A mA;
*	}
*	static assert(!(CheckTreeExpanding!S2));
*	-----------
*/
template CheckTreeExpanding(Aggregate)
{
	template FTypeTuple(T, pfields...)
	{
		enum fields = pfields[0];
		static if(fields.length > 0)
			alias TypeTuple!(getMemberType!(T, fields[0]), FTypeTuple!(T, fields[1..$])) FTypeTuple;
		else
			alias TypeTuple!() FTypeTuple;
	}

	template MembersCheck(T, Restricted...)
	{
		enum fields = SatisfyFieldTuple!(T, isAggregateType);
		alias FTypeTuple!(T, fields) tfields;

		template CheckRestricted(TList...)
		{
			static if(TList.length > 0)
			{
				alias TList[0..1] head;
				alias TList[1..$] tail;

				static if( staticIndexOf!(head, tfields) == -1 && !is(head == T))
					enum CheckRestricted = CheckRestricted!(tail);
				else
					enum CheckRestricted = false;
			}
			else
				enum CheckRestricted = true;
		}

		template CheckFields(TList...)
		{
			static if(TList.length > 0)
			{
				alias TList[0..1] head;
				alias TList[1..$] tail;

				static if( MembersCheck!(head, TypeTuple!(T, Restricted)) )
					enum CheckFields = CheckFields!(tail);
				else
					enum CheckFields = false;
			}
			else
				enum CheckFields = true;
		}

		static if(CheckRestricted!(Restricted))
			enum MembersCheck = CheckFields!(tfields);
		else
			enum MembersCheck = false;
	}

	enum CheckTreeExpanding = MembersCheck!(Aggregate, TypeTuple!());
}

unittest
{
	class A
	{
		bool a;
		string b;

		class B
		{
			bool val;
		}
		class C
		{
			B mB;
		}

		B mB;
	}
	static assert(CheckTreeExpanding!A);

	class S1
	{
		class A
		{
			class B
			{
				S1 mS;
			}
			B mB;
		}
		A mA;
	}
	static assert(!(CheckTreeExpanding!S1));

	class S2
	{
		class A
		{
			C mC;
		}
		class B
		{
			A mA;
		}
		class C
		{
			B mB;
		}
		A mA;
	}
	static assert(!(CheckTreeExpanding!S2));

	class S3
	{

	}
	static assert(CheckTreeExpanding!S3);
}

/// Descriptor of backend read/write place
alias size_t PlaceId;

/// WriteValueException
/**
*	Occures when some serialization write error happens.
*/
class WriteValueException(Type) : Exception
{
	/**
	*	$(B id) describes where error occures, $(B name) describes member name which causes problem and
	*	some message $(B msg) describing problem in few words.
	*/
	this(PlaceId id, string name, lazy string msg)
	{
		super(msg);
		mId = id;
		mName = name;
	}

	PlaceId mId;
	string mName;
}

/// ReadValueException
/**
*	Occures when some deserialization read error happens.
*/
class ReadValueException(Type) : Exception
{
	/**
	*	$(B id) describes where error occures, $(B name) describes member name which causes problem and
	*	some message $(B msg) describing problem in few words.
	*/
	this(PlaceId id, string name, lazy string msg)
	{
		super(msg);
		mId = id;
		mName = name;
	}

	PlaceId mId;
	string mName;
}

/// ArchiveGenerator
/**
*	This template realizes frontend serialization part and provides interface for creating backends.
*
*	$(B How to create backend:) first mixin this template into your class, then realize functions below:
*	---------
*	public:
*		PlaceId getRootPlace();
*
*		Stream 	writeStream();
*		void	writeFile(string name);
*
*		void	readStream(Stream stream);
*		void	readFile(string name);
*
* 	protected:
*		PlaceId writeClass(Class)(PlaceId parent, string name, Class val);
*		PlaceId writeStruct(Struct)(PlaceId parent, string name, Struct val);
*		PlaceId writeClassArray(Element)(PlaceId parent, string name, Element[] val);
*		PlaceId writeStructArray(Element)(PlaceId parent, string name, Element[] val);
*
*		void writePlainField(Type)(PlaceId parent, string name, Type val);
*		void writeArray(Type)(PlaceId parent, string name, Type val);
*		void writeAssociativeArray(Type)(PlaceId parent, string name, Type val);
*
*		size_t getClassArraySize(Element)(PlaceId parent, string name);
*		size_t getStructArraySize(Element)(PlaceId parent, string name);
*
*		bool isClassExists(Class)(PlaceId parent, string name);
*		bool isStructExists(Struct)(PlaceId parent, string name);
*		bool isClassArrayExists(Element)(PlaceId parent, string name);
*		bool isStructArrayExists(Element)(PlaceId parent, string name);
*
*		bool isPlainFieldExists(Type)(PlaceId parent, string name);
*		bool isArrayExists(Type)(PlaceId parent, string name);
*		bool isAssociativeArrayExists(Type)(PlaceId parent, string name);
*
*		PlaceId getStructPlace(Struct)(PlaceId parent,string name);
*		PlaceId getClassPlace(Class)(PlaceId parent,string name);
*		PlaceId getClassArrayPlace(Element)(PlaceId parent, string name);
*		PlaceId getStructArrayPlace(Element)(PlaceId parent, string name);
*
*		Type readPlainField(Type)(PlaceId parent, string name);
*		Type readArray(Type)(PlaceId parent, string name);
*		Type readAssociativeArray(Type)(PlaceId parent, string name);
*	---------
*
*	Template assumes that inner implementation is closed, thats why backend interface uses PlaceId (size_t alias), descriptor wich
*	helps determine where frontend wanted to place data, it can be array index or pointer, frontend doesn't care. Detailed interface
*	description below:
*
*	$(B getRootPlace): Retrives place descriptor of tree root. It is first place to write accessible after acrhvie initialization.
*
*	$(B getStructPlace): Retrives place descriptor of $(B Struct) with $(B name) from place $(B parent). If cannot find, should throw ReadValueException.
*
*	$(B getClassPlace): Retrives place descriptor of $(B Class) with $(B name) from place $(B parent). If cannot find, should throw ReadValueException.
*
*	$(B getClassArrayPlace): Retrives place descriptor of $(B Element) class array with $(B name) from place $(B parent). If cannot find, should throw ReadValueException.
*
*	$(B getStructArrayPlace): Retrives place descriptor of $(B Element) struct array with $(B name) from place $(B parent). If cannot find, should throw ReadValueException.
*
*	$(B getClassArraySize): Returns actual size of readed class array with name $(B name) and element type $(B Element) from place $(B parent). If cannot find, should throw ReadValueException.
*
*	$(B getClassArraySize): Returns actual size of readed struct array with name $(B name) and element type $(B Element) from place $(B parent). If cannot find, should throw ReadValueException.
*
*	$(B isClassExists): Checks existance of $(B Class) at place $(B parent). Returns true if exists, false else.
*
*	$(B isStructExists): Checks existance of $(B Struct) at place $(B parent). Returns true if exists, false else.
*
*	$(B isPlainFieldExists): Checks existance of POD field $(B Type) at place $(B parent). Returns true if exists, false else.
*
*	$(B isArrayExists): Checks existance of POD array data field $(B Type) at place $(B parent). Returns true if exists, false else.
*
*	$(B isClassArrayExists): Checks existance of class array field with element $(B Element) at place $(B parent). Returns true if exists, false else.
*
*	$(B isStructArrayExists): Checks existance of struct array field with element $(B Element) at place $(B parent). Returns true if exists, false else.
*
*	$(B isAssociativeArrayExists): Checks existance of POD associative array data field $(B Type) at place $(B parent). Returns true if exists, false else.
*
*	$(B writeStream): Writes down all accumulated information in memory stream. This operation occurs after all data loaded in backend generator.
*
*	$(B writeFile): Writes down all accumulated information in a file with $(B name). This operation occurs after all data loaded in backend generator.
*
*	$(B readStream): Reads all information for deserialization from $(B stream). This operation occurs befor all data reading operations.
*
*	$(B readFile): Reads all information for deserialization from file $(B name). This operation occurs befor all data reading operations.
*
*	$(B writeClass): Adds $(B Class) to archive at place $(B parent) with $(B name). This method should only prepare new place for data and return $(B PlaceId).
*	All actual data will be passed throught $(B writePlainField), $(B writeArray), $(B writeAssociativeArray), but class instance $(B val) passes to method
*	for some meta-data records. Seperate interfaces for classes and structs helps seperate serialization semantic, although inner backend implementation can
*	write classes and structs with single algorithm.
*
*	$(B writeStruct): Adds $(B Struct) to archive at place $(B parent) with $(B name). This method should only prepare new place for data and return $(B PlaceId).
*	All actual data will be passed throught $(B writePlainField), $(B writeArray), $(B writeAssociativeArray), but struct instance $(B val) passes to method
*	for some meta-data records. Seperate interfaces for classes and structs helps seperate serialization semantic, although inner backend implementation can
*	write classes and structs with single algorithm.
*
*	$(B writeClassArray): Adds array of $(B Element) to archive at place $(B parent) with name $(B name). This method should only prepare new place for data
*	and return $(B PlaceId).
*
*	$(B writeStructArray): Adds array of $(B Element) to archive at place $(B parent) with name $(B name). This method should only prepare new place for data
*	and return $(B PlaceId).
*
*	$(B writePlainField): Adds $(B Type) POD field to archive at place $(B parent) with $(B name).
*
*	$(B writeArray): Adds $(B Type) array of POD data to archive at place $(B parent) with $(B name). Currently array of objects or structs doesn't work correct.
*
*	$(B writeAssociativeArray): Adds $(B Type) associative array of POD data to archive at place $(B parent) with $(B name). Currently array of objects or structs
*	doesn't work correct.
*
*	$(B readPlainField): Gets $(B Type) POD field from archive at place $(B parent) with $(B name).
*
*	$(B readArray): Gets $(B Type) array of POD data from archive at place $(B parent) with $(B name).
*
*	$(B readAssociativeArray): Gets $(B Type) associatvie array of POD data from archive at place $(B parent) with $(B name).
*
*	TODO: maps of aggregate types.
*
*	Notes: All template class members are final by default in D. This causes many problems when organazing complex compile-time architecture, thats why
*		ArchiveGenerator is mixin template. This is another way to provide polymorphic behave, but you should check all methods yourself, compiler won't do this.
*/
mixin template ArchiveGenerator()
{
	import util.common, std.traits, std.stdio;
public:

	/// writeAggregate
	/**
	*	Writes $(B Aggregate) type to arhive at place $(B parent) with $(B name). This method actually writes down all class/struct to archive, not only allocates
	*	place for data. All nested classes and structs will be recorded in parent one. Type instance $(B val) passed to record some usefull metadata (backend functionality).
	*	Method uses backend inteface to low-level write operations.
	*
	*	Throws:
	*		$(B WriteValueException) if names clashes detected.
	*/
	PlaceId writeAggregate(Aggregate)(PlaceId parent, string name, Aggregate val)
	in
	{
		static assert(isAggregateType!Aggregate && !is(Aggregate == union) && !is(Aggregate == interface), "writeAggregate can write only class/struct types!");
	}
	body
	{
		// preparing compile-time info
		alias FieldNameTuple!(Aggregate) fieldNames;
		alias TypeTupleFrom!(Aggregate, fieldNames) fieldTypes;

		// checking place
		if(isAggregateExists!Aggregate(parent, name))
			throw new WriteValueException!Aggregate(parent, name, "aggregate field "~name~" is already exists at writing place!");

		// allocating place
		PlaceId ret;
		static if(is(Aggregate == class))
		{
			ret = writeClass!Aggregate(parent, name, val);
		}
		else static if(is(Aggregate == struct))
		{
			ret = writeStruct!Aggregate(parent, name, val);
		}

		// foreach field writes at new place
		foreach(i,memt; fieldTypes)
		{
			static if(isAggregateType!memt)
			{
				if(isAggregateExists!memt(ret, fieldNames[i]))
					throw new WriteValueException!Aggregate(ret, fieldNames[i], "aggregate field "~fieldNames[i]~" is already exists at writing place!");
				writeAggregate!(memt)(ret, fieldNames[i], mixin("val."~fieldNames[i]));
			} else
			{
				if(isFieldExists!memt(ret, fieldNames[i]))
					throw new WriteValueException!Aggregate(ret, fieldNames[i], "field "~fieldNames[i]~" is already exists at writing place!");
				writeField!(memt)(ret, fieldNames[i], mixin("val."~fieldNames[i]));
			}
		}
		return ret;
	}

	/// writeAggregateArray
	/**
	*	Writes down array of aggregate type $(B Element) to archive at place $(B parent) with name $(B name). This method actually
	*	writes down all class/struct to archive, not only allocates place for data. All nested classes and structs will be recorded
	*	in parent one. Array instance $(B val) passed to record some usefull metadata (backend functionality).
	*	Method uses backend inteface to low-level write operations.
	*
	*	Throws:
	*		$(B WriteValueException) if names clashes detected.
	*/
	void writeAggregateArray(Element)(PlaceId parent, string name, Element[] val)
	{
		// checking place
		if(isAggregateArrayExists!Element(parent, name))
			throw new WriteValueException!Element(parent, name, "aggregate array field "~name~" is already exists at writing place!");

		// allocating place
		PlaceId ret;
		static if(is(Element == class))
		{
			ret = writeClassArray!Element(parent, name, val);
		}
		else static if(is(Element == struct))
		{
			ret = writeStructArray!Element(parent, name, val);
		}

		// writing elements
		foreach(i,e; val)
		{
			writeAggregate!Element(ret, name~"_"~to!string(i), e);
		}
	}

	/// writeField
	/**
	*	Send $(B Type) to backend to be written.
	*	Method redirects call to backend interface depending on $(B Type) actual type.
	*/
	void writeField(Type)(PlaceId parent, string name, Type val)
	in
	{
		static assert(!isAggregateType!Type, "writeField can write only plain types!");
	}
	body
	{
		static if(isArray!Type)
		{
			alias ArrayElementType!Type Element;
			static if(isAggregateType!Element)
				writeAggregateArray!Element(parent, name, val);
			else
				writeArray!(Type)(parent, name, val);
		} else static if(isAssociativeArray!Type)
		{
			writeAssociativeArray!(Type)(parent, name, val);
		} else
		{
			writePlainField!(Type)(parent, name, val);
		}
	}

	/// isAggregateExists
	/**
	*	Checks if struct/class $(B Aggregate) is exists at backend place $(B parent) storage.
	*	Method redirects call to backend interface depending on $(B Aggregate) actual type;
	*/
	bool isAggregateExists(Aggregate)(PlaceId parent, string name)
	in
	{
		static assert(isAggregateType!Aggregate && !is(Aggregate == union) && !is(Aggregate == interface), "isAggregateExists can check only class/struct types!");
	}
	body
	{
		static if(is(Aggregate == class))
			return isClassExists!Aggregate(parent, name);
		else
			return isStructExists!Aggregate(parent, name);
	}

	/// isAggregateArrayExists
	/**
	*	Checks if aggregate array of $(B Element) type exists at place $(B parent) with name $(B name).
	*	Method redirects call to backend interface depending on $(B Element) actual type;
	*/
	bool isAggregateArrayExists(Element)(PlaceId parent, string name)
	in
	{
		static assert(isAggregateType!Element && !is(Element == union) && !is(Element == interface), "isAggregateArrayExists can check only class/struct types!");
	}
	body
	{
		static if(is(Element == class))
			return isClassArrayExists!Element(parent, name);
		else
			return isStructArrayExists!Element(parent, name);
	}

	/// isFieldExists
	/**
	*	Checks if field $(B Type) is exists at backend place $(B parent) storage.
	*	Method redirects call to backend interface depending on $(B Aggregate) actual type;
	*/
	bool isFieldExists(Type)(PlaceId parent, string name)
	in
	{
		static assert(!isAggregateType!Type, "writeField can write only plain types!");
	}
	body
	{
		static if(isArray!Type)
		{
			alias ArrayElementType!Type Element;
			static if(isAggregateType!Element)
				return isAggregateArrayExists!Element(parent, name);
			else
				return isArrayExists!(Type)(parent, name);
		} else static if(isAssociativeArray!Type)
		{
			return isAssociativeArrayExists!(Type)(parent, name);
		} else
		{
			return isPlainFieldExists!(Type)(parent, name);
		}
	}

	/// readAggregate
	/**
	*	Read $(B Aggregate) type from arhive at place $(B parent) with $(B name). This method actually reads recursive all class/struct from archive.
	*	All nested classes and structs will be recorder in parent one. Method uses backend inteface to low-level write operations.
	*
	*	Throws:
	*		$(B ReadValueException) if names clashes detected or some other problems detected.
	*/
	Aggregate readAggregate(Aggregate)(PlaceId parent, string name)
	in
	{
		static assert(isAggregateType!Aggregate && !is(Aggregate == union) && !is(Aggregate == interface), "readAggregate can read only class/struct types!");
	}
	body
	{
		// preparing compile-time info
		alias FieldNameTuple!(Aggregate) fieldNames;
		alias TypeTupleFrom!(Aggregate, fieldNames) fieldTypes;

		// checking place
		if(!isAggregateExists!Aggregate(parent, name))
			throw new ReadValueException!Aggregate(parent, name, "aggregate field with name '"~name~"' and type '"~Aggregate.stringof~"' isn't exists at reading place!");

		// creating instance and getting place
		static if(is(Aggregate == class))
		{
			static assert(__traits(compiles, "auto ret = new Aggregate()"), Aggregate.stringof~" must have constructor without parameters to deserialize!");
			auto ret = new Aggregate();
			auto place = getClassPlace!Aggregate(parent, name);
		}
		else static if(is(Aggregate == struct))
		{
			Aggregate ret;
			auto place = getStructPlace!Aggregate(parent, name);
		}

		// foreach field reading
		foreach(i,memt; fieldTypes)
		{
			static if(isAggregateType!memt)
			{
				if(!isAggregateExists!memt(place, fieldNames[i]))
					throw new ReadValueException!memt(place, fieldNames[i], "aggregate field with name '"~fieldNames[i]~"' and type '"~memt.stringof~"' isn't exists at reading place!");
				mixin("ret."~fieldNames[i]) = readAggregate!(memt)(place, fieldNames[i]);
			} else
			{
				if(!isFieldExists!memt(place, fieldNames[i]))
					throw new ReadValueException!memt(place, fieldNames[i], "field with name '"~fieldNames[i]~"' and type '"~memt.stringof~"' isn't exists at reading place!");
				mixin("ret."~fieldNames[i]) = readField!(memt)(place, fieldNames[i]);
			}
		}
		return ret;
	}

	/// readAggregateArray
	/**
	*	Read aggregate array with element type $(B Element) from arhive at place $(B parent) with $(B name). This method actually reads
	*	recursive all class/struct from archive. All nested classes and structs will be recorder in parent one. Method uses backend inteface
	*	to low-level write operations.
	*
	*	Throws:
	*		$(B ReadValueException) if names clashes detected or some other problems detected.
	*/
	Element[] readAggregateArray(Element)(PlaceId parent, string name)
	in
	{
		static assert(isAggregateType!Element && !is(Element == union) && !is(Element == interface), "readAggregateArray can read only class/struct types!");
	}
	body
	{
		// checking place
		if(!isAggregateArrayExists!Element(parent, name))
			throw new ReadValueException!Element(parent, name, "aggregate array field with name '"~name~"' and type '"~Element.stringof~"' isn't exists at reading place!");


		// creating instance and getting place
		auto ret = new Element[getAggregateArraySize!Element(parent, name)];
		static if(is(Element == class))
		{
			auto place = getClassArrayPlace!Element(parent, name);
		}
		else static if(is(Element == struct))
		{
			auto place = getStructArrayPlace!Element(parent, name);
		}

		// reading elements
		foreach(i, ref e; ret)
		{
			e = readAggregate!Element(place, name~"_"~to!string(i));
		}
		return ret;
	}

	/// getAggregateArraySize
	/**
	*	Returns actual size of array $(B name) with element type $(B Element) at place $(B parent).
	*	Method redirects call to backend interface depending on $(B Element) actual type.
	*/
	size_t getAggregateArraySize(Element)(PlaceId parent, string name)
	in
	{
		static assert(isAggregateType!Element && !is(Element == union) && !is(Element == interface), "getAggregateArraySize can work only with class/struct types!");
	}
	body
	{
		static if(is(Element == class))
			return getClassArraySize!(Element)(parent, name);
		else
			return getStructArraySize!(Element)(parent, name);
	}

	/// readField
	/**
	*	Reads $(B Type) from archive at place $(B parent) with $(B name).
	*	Method redirects call to backend interface depending on $(B Type) actual type.
	*/
	Type readField(Type)(PlaceId parent, string name)
	in
	{
		static assert(!isAggregateType!Type, "readField can read only plain types!");
	}
	body
	{
		static if(isArray!Type)
		{
			alias ArrayElementType!Type Element;
			static if(isAggregateType!Element)
				return readAggregateArray!Element(parent, name);
			else
				return readArray!Type(parent, name);
		} else static if(isAssociativeArray!Type)
		{
			return readAssociativeArray!Type(parent, name);
		} else
		{
			return readPlainField!Type(parent, name);
		}
	}
}

/*
*	Simple themplate delegate, used in $(B serializeToStream), $(B serializeToFile).
*/
private template isNotAggregateType(T)
{
	enum isNotAggregateType = !isAggregateType!(T);
}

/*
*	Checks if T in fact has needed methods. Virtual functions don't work with templates, thats why we need some other
*	way to provide polimorphic behave.
*/
private template checkArchiveType(T)
{
	enum checkArchiveType =
		hasMember!(T, "writeClass") 		&& hasMember!(T, "writeStruct") 			&& hasMember!(T, "writePlainField") 		&&
		hasMember!(T, "writeArray") 		&& hasMember!(T, "writeAssociativeArray") 	&& hasMember!(T, "writeStream") 			&&
		hasMember!(T, "writeFile") 			&& hasMember!(T, "getRootPlace") 			&& hasMember!(T, "writeAggregate") 			&&
		hasMember!(T, "writeField") 		&& hasMember!(T, "isAggregateExists") 		&& hasMember!(T, "isFieldExists") 			&&
		hasMember!(T, "readArray") 			&& hasMember!(T, "readAssociativeArray") 	&& hasMember!(T, "readPlainField") 			&&
		hasMember!(T, "readAggregate") 		&& hasMember!(T, "readField")				&& hasMember!(T, "readStream")				&&
		hasMember!(T, "readFile")			&& hasMember!(T, "writeAggregateArray")		&& hasMember!(T, "readAggregateArray")		&&
		hasMember!(T, "writeClassArray")	&& hasMember!(T, "writeStructArray")		&& hasMember!(T, "isAggregateArrayExists") 	&&
		hasMember!(T, "isClassArrayExists") && hasMember!(T, "isStructArrayExists")		&& hasMember!(T, "getClassArrayPlace")		&&
		hasMember!(T, "getStructArrayPlace")&& hasMember!(T, "getAggregateArraySize")	&& hasMember!(T, "getStructArraySize")		&&
		hasMember!(T, "getClassArraySize");
}

/// serialize
/**
*	Serializes one aggregate type $(B T) to stream using $(B ArchiveType) backend. Type will be tested to be serialized in tree
*	structure (cross references are restricted). $(B ArchiveType) should have frontend methods (mixin $(B ArhiveGenerator)) and
*	should realize backend interface, otherwise compile-time error occures.
*
*	Example:
*	----------
*	class B
*	{
*		string d = "some string";
*
*		string[string] someMap;
*
*		this()
*		{
*			someMap = ["key1":"value1", "key2":"value2", "key3":"value3"];
*		}
*	}
*
*	class A
*	{
*		int a = 1;
*		bool b = true;
*		string c = "another string";
*		B mB;
*
*		this()
*		{
*			mB = new B();
*		}
*	}
*
*	A test = new A;
*	auto stream = serialize!GendocArchive(test, "someTestClass");
*	----------
*/
Stream serialize(ArchiveType, T)(T aggregate, string name = "")
	if(isAggregateType!T && !is(T == union))
{
	static assert(CheckTreeExpanding!T, "Type "~T.stringof~" cannot be serialized due cross refs in it structure!");
	static assert(checkArchiveType!(ArchiveType), "Archive "~ArchiveType.stringof~" is not implementing ArchiveGenerator backend or not mixin frontend!");

	if(name == "")
		name = T.stringof;

	auto archive = new ArchiveType;

	try
	{
		archive.writeAggregate(archive.getRootPlace(), name, aggregate);
	}
	catch(Exception e)
	{
		throw new Exception("Failed to serialize aggregate "~T.stringof~". Reason: "~e.msg);
	}

	Stream ret;
	try
	{
		ret = archive.writeStream();
	}
	catch(Exception e)
	{
		throw new Exception("Failed to serialize aggregate "~T.stringof~". Reason: failed writing down in stream. Details: "~e.msg);
	}

	return ret;
}

/// deserialize
/**
*	Deserializes one aggregate type $(B T) from ($B stream) using $(B ArchiveType) backend. Type will be tested to be serialized in tree
*	structure (cross references are restricted). $(B ArchiveType) should have frontend methods (mixin $(B ArhiveGenerator)) and
*	should realize backend interface, otherwise compile-time error occures.
*
*	Example:
*	----------
*	class B
*	{
*		string d = "some string";
*
*		string[string] someMap;
*
*		this()
*		{
*			someMap = ["key1":"value1", "key2":"value2", "key3":"value3"];
*		}
*	}
*
*	class A
*	{
*		int a = 1;
*		bool b = true;
*		string c = "another string";
*		B mB;
*
*		this()
*		{
*			mB = new B();
*		}
*	}
*
*	A test = new A;
*	auto stream = serialize!GendocArchive(test, "someTestClass");
*
*	stream.position = 0;
*	auto c = deserialize!(GendocArchive, A)(stream, "someTestClass");
*
*	assert(c.a == 1);
*	assert(c.b);
*	assert(c.c == "another string");
*	assert(c.mB.d == "some string");
*	assert(c.mB.someMap == ["key1":"value1", "key2":"value2", "key3":"value3"]);
*	----------
*/
T deserialize(ArchiveType, T)(Stream stream, string name="")
	if(isAggregateType!T && !is(T == union))
{
	static assert(CheckTreeExpanding!T, "Type "~T.stringof~" cannot be deserialized due cross refs in it structure!");
	static assert(checkArchiveType!(ArchiveType), "Archive "~ArchiveType.stringof~" is not implementing ArchiveGenerator backend or not mixin frontend!");

	if(name == "")
		name = T.stringof;

	auto archive = new ArchiveType;

	try
	{
		archive.readStream(stream);
	}
	catch(Exception e)
	{
		throw new Exception("Failed to deserialize aggregate "~T.stringof~". Reason: failed loading raw data from stream. Details: "~e.msg);
	}

	T ret;
	try
	{
		ret = archive.readAggregate!T(archive.getRootPlace(), name);
	}
	catch(Exception e)
	{
		throw new Exception("Failed to deserialize aggregate "~T.stringof~". Reason: "~e.msg);
	}

	return ret;
}

/// serialize
/**
*	Serializes one aggregate type $(B T) to file with $(B name) using $(B ArchiveType) backend. Type will be tested to be serialized in tree
*	structure (cross references are restricted). $(B ArchiveType) should have frontend methods (mixin $(B ArhiveGenerator)) and
*	should realize backend interface, otherwise compile-time error occures.
*
*	Example:
*	----------
*	class B
*	{
*		string d = "some string";
*
*		string[string] someMap;
*
*		this()
*		{
*			someMap = ["key1":"value1", "key2":"value2", "key3":"value3"];
*		}
*	}
*
*	class A
*	{
*		int a = 1;
*		bool b = true;
*		string c = "another string";
*		B mB;
*
*		this()
*		{
*			mB = new B();
*		}
*	}
*
*	A test = new A;
*	serialize!GendocArchive(test, "someTestClass", "testingSerializer.txt");
*	----------
*/
void serialize(ArchiveType, T)(T aggregate, string filename, string name = "")
	if(isAggregateType!T && !is(T == union))
{
	static assert(CheckTreeExpanding!T, "Type "~T.stringof~" cannot be serialized due cross refs in it structure!");
	static assert(checkArchiveType!(ArchiveType), "Archive "~ArchiveType.stringof~" is not implementing ArchiveGenerator backend or not mixin frontend!");

	if(name == "")
		name = T.stringof;

	auto archive = new ArchiveType;
	try
	{
		archive.writeAggregate(archive.getRootPlace(), name, aggregate);
	}
	catch(Exception e)
	{
		throw new Exception("Failed to serialize aggregate "~T.stringof~". Reason: "~e.msg);
	}

	try
	{
		archive.writeFile(filename);
	}
	catch(Exception e)
	{
		throw new Exception("Failed to serialize aggregate "~T.stringof~". Reason: failed writing down in stream. Details: "~e.msg);
	}
}

/// deserialize
/**
*	Deserializes one aggregate type $(B T) from file ($B filename) using $(B ArchiveType) backend. Type will be tested to be serialized in tree
*	structure (cross references are restricted). $(B ArchiveType) should have frontend methods (mixin $(B ArhiveGenerator)) and
*	should realize backend interface, otherwise compile-time error occures.
*
*	Example:
*	----------
*	class B
*	{
*		string d = "some string";
*
*		string[string] someMap;
*
*		this()
*		{
*			someMap = ["key1":"value1", "key2":"value2", "key3":"value3"];
*		}
*	}
*
*	class A
*	{
*		int a = 1;
*		bool b = true;
*		string c = "another string";
*		B mB;
*
*		this()
*		{
*			mB = new B();
*		}
*	}
*
*	A test = new A;
*	serialize!GendocArchive(test, "someTestClass", "test.txt");
*
*	auto c = deserialize!(GendocArchive, A)("test.txt", "someTestClass");
*
*	assert(c.a == 1);
*	assert(c.b);
*	assert(c.c == "another string");
*	assert(c.mB.d == "some string");
*	assert(c.mB.someMap == ["key1":"value1", "key2":"value2", "key3":"value3"]);
*	----------
*/
T deserialize(ArchiveType, T)(string filename, string name = "")
	if(isAggregateType!T && !is(T == union))
{
	static assert(CheckTreeExpanding!T, "Type "~T.stringof~" cannot be deserialized due cross refs in it structure!");
	static assert(checkArchiveType!(ArchiveType), "Archive "~ArchiveType.stringof~" is not implementing ArchiveGenerator backend or not mixin frontend!");

	if(name == "")
		name = T.stringof;

	auto archive = new ArchiveType;

	try
	{
		archive.readFile(filename);
	}
	catch(Exception e)
	{
		throw new Exception("Failed to deserialize aggregate "~T.stringof~". Reason: failed loading raw data from stream. Details: "~e.msg);
	}

	T ret;
	try
	{
		ret = archive.readAggregate!T(archive.getRootPlace(), name);
	}
	catch(Exception e)
	{
		throw new Exception("Failed to deserialize aggregate "~T.stringof~". Reason: "~e.msg);
	}

	return ret;
}

version(unittest)
{
	class B
	{
		string d = "some string";

		string[string] someMap;

		this()
		{
			someMap = ["key1":"value1", "key2":"value2", "key3":"value3"];
		}
	}

	class A
	{
		int a = 1;
		bool b = true;
		string c = "another string";
		B mB;

		this()
		{
			mB = new B();
		}
	}

	struct C
	{
		string name;
		struct SC
		{
			int id;
			string name;
		}
		SC[] groups;

		class SD
		{
			bool val;
		}
		SD[] vals;
	}
}
unittest
{
	import std.stdio;
	write("Testing serialization... ");
	scope(success) writeln("Finished!");
	scope(failure) writeln("Failed!");

	foreach(Backend; TypeTuple!(GendocArchive, BinaryArchive))
	{
		A test = new A;

		auto stream = serialize!Backend(test, "someTestClass");
		stream.position = 0;
		auto c = deserialize!(Backend, A)(stream, "someTestClass");

		assert(c.a == 1);
		assert(c.b);
		assert(c.c == "another string");
		assert(c.mB.d == "some string");
		assert(c.mB.someMap == ["key1":"value1", "key2":"value2", "key3":"value3"]);

		serialize!Backend(test, "testingSerializer.txt", "someTestClass");
		c = deserialize!(Backend, A)("testingSerializer.txt", "someTestClass");

		assert(c.a == 1);
		assert(c.b);
		assert(c.c == "another string");
		assert(c.mB.d == "some string");
		assert(c.mB.someMap == ["key1":"value1", "key2":"value2", "key3":"value3"]);

		C mC;
		mC.name = "testName";
		mC.groups = new mC.SC[3];
		mC.vals = new mC.SD[2];

		mC.groups[0].id = 0;
		mC.groups[0].name = "group1";
		mC.groups[1].id = 1;
		mC.groups[1].name = "group2";
		mC.groups[2].id = 2;
		mC.groups[2].name = "group3";

		mC.vals[0] = new mC.SD;
		mC.vals[0].val = true;
		mC.vals[1] = new mC.SD;
		mC.vals[1].val = false;

		stream = serialize!Backend(mC);
		stream.position = 0;
		mC = deserialize!(Backend, C)(stream);

		assert(mC.name == "testName");
		assert(mC.groups !is null);
		assert(mC.groups[0].id == 0 && mC.groups[0].name == "group1");
		assert(mC.groups[1].id == 1 && mC.groups[1].name == "group2");
		assert(mC.groups[2].id == 2 && mC.groups[2].name == "group3");
		assert(mC.vals[0].val);
		assert(!mC.vals[1].val);
	}
}
