//          Copyright Gushcha Anton 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
/// Менджер управляет набором доступных кодеков, регистрирует, исключает кодеки.
/**
*	@file codecmng.d Менджер управляет набором доступных кодеков, регистрирует, исключает кодеки.
*	Ищет подходящий кодек по расширению или ключевому слову.
*/
module util.codecmng;

public import util.codec;
import util.log;
import util.singleton;

/// Менджер управляет набором доступных кодеков, регистрирует, исключает кодеки.
class CodecMng
{
	mixin Singleton!CodecMng;

	/// Зарегистрировать кодек в менджере
	/**
	*	@par inst Экземпляр кодека
	*	@return true при успехе, false при неудаче
	*/
	bool registerCodec(Codec inst)
	{
		if( inst.type in mCodecs )
		{
			writeLog("CodecMng: codec "~inst.type~" already have been registered!", LOG_ERROR_LEVEL.WARNING);
			return false;
		}

		mCodecs[inst.type] = inst;
		return true;
	}

	/// Получение кодека по идентификатору
	/**
	*	@par type Идентификатор кодека
	*	@note Кидает исключение, если не зарегистрирован.
	*/
	Codec getCodec(string type)
	{
		if( type in mCodecs )
			return mCodecs[type];

		writeLog("CodecMng: Cannot find codec "~type~"!", LOG_ERROR_LEVEL.FATAL);
		throw new Exception("CodecMng: Cannot find codec "~type~"!");
	}

	/// Получение списка кодеков одного стандарта
	/**
	*	Возвращает список кодеков, поддерживающих единный
	*	стандарт.
	*/
	Codec[] getByStandart(string standart)
	{
		auto ret = new Codec[0];

		foreach(c; mCodecs)
			if(c.standart == standart) 
				ret ~= c;

		return ret;
	}

private:
	Codec[string] mCodecs;
}
