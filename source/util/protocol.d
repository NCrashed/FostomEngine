// written in the D programming language
/**
*   Copyright: © 2012-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*	Modules simplifies message dispatching and client-server protocol. Ids and message connects once and then you can forget about 
*	id existance when getting and sending messages.
*
*	Example:
*	--------
*	class AMsg : PMessage
*	{
*		int a;
*		string b;
*
*		this() {}
*
*		this(int pa, string pb)
*		{
*			a = pa;
*			b = pb;
*		}
*
*		void opCall()
*		{
*			writeln("AMsg call with ", a, " ", b);
*		}
*	}
*
*	class BMsg : PMessage
*	{
*		double a;
*		double b;
*
*		this() {}
*
*		this(double pa, double pb)
*		{
*			a = pa;
*			b = pb;
*		}
*
*		void opCall()
*		{
*			writeln("BMsg call with ", a, " ", b);
*		}
*	}
*
*	class CMsg : PMessage
*	{
*		double a;
*		string s;
*
*		this() {}
*
*		this(double pa, string ps)
*		{
*			a = pa;
*			s = ps;
*		}
*
*		void opCall()
*		{
*			writeln("CMsg call ", a, " ", s);
*		}
*	}
*
*	mixin ProtocolPool!(int, GendocArchive,
*		0, AMsg, 
*		1, BMsg,
*		2, CMsg
*		);
*
*	void readMsg(Stream stream)
*	{
*		int id;
*		stream.read(id);
*		writeln("got message id is ",id);
*		auto message = dispatchMessage!(deserialize)(id, stream, "MSG");
*		writeln("Calling message");
*		message();
*	}
*
*	// serializing
*	auto stream = constructMessage!BMsg(4.0,8.0);
*	// sending...
*	// got at other side
*	readMsg(stream);
*
*	stream = constructMessage!AMsg(10, "Hello World!");
*	readMsg(stream);
*
*	stream = constructMessage!CMsg(5., "Some usefull string");
*	readMsg(stream);
*
*	--------
*/
module util.protocol;

import std.stdio;
import std.conv;

import util.serialization.serializer;


/**
*	Templates wich helps declare protocol and connect messages with correspondign ids. $(B IndexType) describes index type
*	wich be used to mark messages. $(B SerializerBackend) helps with flexible serializer setting. $(B pairs) is a list formed
*	from pairs of id and message type.
*
*	Example:
*	--------
*	mixin ProtocolPool!(int, GendocArchive,
*		0, AMsg, 
*		1, BMsg,
*		2, CMsg
*		);
*	-------- 
*/
mixin template ProtocolPool(IndexType, SerializerBackend, pairs...)
{
	import std.stdio;
	import std.conv;
	/**
	*	All messages have to implement this interface despy it's very simple. 
	*	Later here can appear some other functions. Also each message should have
	*	constructor without pars to be deserialized.
	*
	*	Example:
	*	--------
	*	class AMsg : PMessage
	*	{
	*		int a;
	*		string b;
	*
	*		this() {}
	*
	*		this(int pa, string pb)
	*		{
	*			a = pa;
	*			b = pb;
	*		}
	*
	*		void opCall()
	*		{
	*			writeln("AMsg call with ", a, " ", b);
	*		}
	*	}
	*	--------
	*/

	interface PMessage
	{
		//string name;
		void opCall();
	}


	// returns count of val occurenes in list
	template CountValInList(IndexType val, list...)
	{
		static if(list.length > 1)
		{
			static if(list[0] == val)
				enum CountValInList = 1 + CountValInList!(val, list[2..$]);
			else
				enum CountValInList = CountValInList!(val, list[2..$]);
		}
		else
			enum CountValInList = 0;
	}

	// check pairs to be correct
	template CheckPairs(tpairs...)
	{
		static if(tpairs.length > 1)
		{
			static assert(__traits(compiles, typeof(tpairs) ), "ProtocolPool expected index first, but got some type");
			static assert(is(typeof(tpairs[0]) == IndexType), "ProtocolPool expected index first of type "~IndexType.stringof~" not a "~typeof(tpairs[0]).stringof);

//			static assert(is(tpairs[1] : PMessage), "ProtocolPool expected class implementing PMessage interface following index not a "~tpairs[1].stringof);

			static assert(CountValInList!(tpairs[0], pairs) == 1, "ProtocolPool indexes must be unique! One message, one index.");

			enum CheckPairs = CheckPairs!(tpairs[2..$]);
		} 
		else
		{
			static assert(tpairs.length == 0, "ProtocolPool expected even number of parameters. Index and message type.");
			enum CheckPairs = 0;
		}
	}

	// generating switch
	template GenerateSwitch()
	{
		template GenerateSwitchBody(tpairs...)
		{
			static if(tpairs.length > 0)
			{
				enum GenerateSwitchBody = "case("~to!string(tpairs[0])~"): return cast(PMessage)(func!(SerializerBackend, "~tpairs[1].stringof~")(args)); break; \n" ~
					GenerateSwitchBody!(tpairs[2..$]);
			} 
			else
				enum GenerateSwitchBody = "";
		}
		enum GenerateSwitch = "switch(id)\n{\n"~GenerateSwitchBody!(pairs) ~ 
			`default: ` ~
			" break;\n}";

	}

	template FindMessageId(Msg, tpairs...)
	{
		static if(tpairs.length > 0)
		{
			static if(is(tpairs[1] == Msg))
				enum FindMessageId = tpairs[0];
			else
				enum FindMessageId = FindMessageId!(Msg, tpairs[2..$]);
		} else
			static assert(false, "Cannot find id for message "~Msg.stringof~". Check protocol list.");
	}

	// actual check
	static assert(CheckPairs!pairs == 0, "Parameters check failed! If code works well, you never will see this message!");

	private class dummyClass {}

	/**
	*	Determines wich message connected to $(B id) at runtime and apply function $(B func) to the message with compile-time argument of
	*	the message type and run-time arguments $(B args). Returns result of $(B func) call casted to $(B PMessage).
	*
	*	Example:
	*	---------
	*	auto message = dispatchMessage!(deserialize)(id, stream, "MSG");
	*	---------
	*/
	PMessage dispatchMessage(alias func, T...)(IndexType id, T args)
	{
		static assert(__traits(compiles, func!(SerializerBackend, dummyClass)(args)), "ChooseMessage func must be callable with got args "~T.stringof);

		//pragma(msg, GenerateSwitch!());
		mixin(GenerateSwitch!());
		throw new Exception("Cannot find corresponding message for id "~to!string(id)~"!");
	}

	/**
	*	Simplifies message constructing. $(B Msg) is a message to be constructed, $(B args) are arguments which will be passed to $(B Msg)
	*	constructor. $(B Msg) should have constructor wich can take $(B T) types. Returns serialized stream, wich can be sended to the other side.
	*
	*	Example:
	*	--------
	*	ubyte[] stream = constructMessage!AMsg(10, "Hello World!");
	*	--------
	*/
	ubyte[] constructMessage(Msg, T...)(T args)
	{
		ubyte[] buf;
		//static assert(is(Msg : PMessage), Msg.stringof~" must implement PMessage interface!");
		static assert(__traits(compiles, new Msg(args)), Msg.stringof~" should implement constructor with formal parameters "~T.stringof);

		auto msg = new Msg(args);
		IndexType sendId = FindMessageId!(Msg, pairs);

		auto stream = serialize!SerializerBackend(msg, "MSG");
		auto fullStream = new MemoryStream;
		fullStream.write(stream.size);
		fullStream.write(sendId);

		fullStream.copyFrom(stream);
		fullStream.position = 0;
		
		buf = new ubyte[cast(size_t) fullStream.size];
		fullStream.read(buf);

		return buf;
	}
}

/*
version(unittest)
{
	mixin ProtocolPool!(int, GendocArchive,
	0, AMsg, 
	1, BMsg,
	2, CMsg
	);

	string buff;
	
	class AMsg : PMessage
	{
		int a;
		string b;

		this() {}

		this(int pa, string pb)
		{
			a = pa;
			b = pb;
		}

		void opCall()
		{
			buff = text("AMsg call with ", a, " ", b);
		}
	}

	class BMsg : PMessage
	{
		double a;
		double b;

		this() {}

		this(double pa, double pb)
		{
			a = pa;
			b = pb;
		}

		void opCall()
		{
			buff = text("BMsg call with ", a, " ", b);
		}
	}

	class CMsg : PMessage
	{
		double a;
		string s;

		this() {}

		this(double pa, string ps)
		{
			a = pa;
			s = ps;
		}

		void opCall()
		{
			buff = text("CMsg call with ", a, " ", s);
		}
	}

}
unittest
{
	void readMsg(Stream stream)
	{
		int id;
		stream.read(id);
		auto message = dispatchMessage!(deserialize)(id, stream, "MSG");
		message();
	}

	write("Testing protocol... ");
	scope(success) writeln("Finished!");
	scope(failure) writeln("Failed!");
	
	// serializing
	auto stream = constructMessage!BMsg(4.0,8.0);
	// sending...
	// got at other side
	readMsg(stream);
	assert(buff == "BMsg call with 4 8", buff);
	
	stream = constructMessage!AMsg(10, "Hello World!");
	readMsg(stream);
	assert(buff == "AMsg call with 10 Hello World!", buff);
	
	stream = constructMessage!CMsg(5., "Some usefull string");
	readMsg(stream);
	assert(buff == "CMsg call with 5 Some usefull string", buff);
}

*/