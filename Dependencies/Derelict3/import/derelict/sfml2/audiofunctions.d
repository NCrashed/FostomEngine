/*

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

*/
module derelict.sfml2.audiofunctions;

private
{
    import derelict.sfml2.systemtypes;
    import derelict.sfml2.audiotypes;
}

extern(C)
{
    alias nothrow void function(float volume) da_sfListener_setGlobalVolume;
    alias nothrow float function() da_sfListener_getGlobalVolume;
    alias nothrow void function(sfVector3f position) da_sfListener_setPosition;
    alias nothrow sfVector3f function() da_sfListener_getPosition;
    alias nothrow void function(sfVector3f orientation) da_sfListener_setDirection;
    alias nothrow sfVector3f function() da_sfListener_getDirection;
    alias nothrow sfMusic* function(const(char)* filename) da_sfMusic_createFromFile;
    alias nothrow sfMusic* function(const(void)* data,size_t sizeInBytes) da_sfMusic_createFromMemory;
    alias nothrow sfMusic* function(sfInputStream* stream) da_sfMusic_createFromStream;
    alias nothrow void function(sfMusic* music) da_sfMusic_destroy;
    alias nothrow void function(sfMusic* music,sfBool loop) da_sfMusic_setLoop;
    alias nothrow sfBool function(const(sfMusic)* music) da_sfMusic_getLoop;
    alias nothrow sfTime function(const(sfMusic)* music) da_sfMusic_getDuration;
    alias nothrow void function(sfMusic* music) da_sfMusic_play;
    alias nothrow void function(sfMusic* music) da_sfMusic_pause;
    alias nothrow void function(sfMusic* music) da_sfMusic_stop;
    alias nothrow uint function(const(sfMusic)* music) da_sfMusic_getChannelCount;
    alias nothrow uint function(const(sfMusic)* music) da_sfMusic_getSampleRate;
    alias nothrow sfSoundStatus function(const(sfMusic)* music) da_sfMusic_getStatus;
    alias nothrow sfTime function(const(sfMusic)* music) da_sfMusic_getPlayingOffset;
    alias nothrow void function(sfMusic* music,float pitch) da_sfMusic_setPitch;
    alias nothrow void function(sfMusic* music,float volume) da_sfMusic_setVolume;
    alias nothrow void function(sfMusic* music,sfVector3f position) da_sfMusic_setPosition;
    alias nothrow void function(sfMusic* music,sfBool relative) da_sfMusic_setRelativeToListener;
    alias nothrow void function(sfMusic* music,float distance) da_sfMusic_setMinDistance;
    alias nothrow void function(sfMusic* music,float attenuation) da_sfMusic_setAttenuation;
    alias nothrow void function(sfMusic* music,sfTime timeOffset) da_sfMusic_setPlayingOffset;
    alias nothrow float function(const(sfMusic)* music) da_sfMusic_getPitch;
    alias nothrow float function(const(sfMusic)* music) da_sfMusic_getVolume;
    alias nothrow sfVector3f function(const(sfMusic)* music) da_sfMusic_getPosition;
    alias nothrow sfBool function(const(sfMusic)* music) da_sfMusic_isRelativeToListener;
    alias nothrow float function(const(sfMusic)* music) da_sfMusic_getMinDistance;
    alias nothrow float function(const(sfMusic)* music) da_sfMusic_getAttenuation;
    alias nothrow sfSound* function() da_sfSound_create;
    alias nothrow sfSound* function(const(sfSound)* sound) da_sfSound_copy;
    alias nothrow void function(sfSound* sound) da_sfSound_destroy;
    alias nothrow void function(sfSound* sound) da_sfSound_play;
    alias nothrow void function(sfSound* sound) da_sfSound_pause;
    alias nothrow void function(sfSound* sound) da_sfSound_stop;
    alias nothrow void function(sfSound* sound,const(sfSoundBuffer)* buffer) da_sfSound_setBuffer;
    alias nothrow const(sfSoundBuffer)* function(const(sfSound)* sound) da_sfSound_getBuffer;
    alias nothrow void function(sfSound* sound,sfBool loop) da_sfSound_setLoop;
    alias nothrow sfBool function(const(sfSound)* sound) da_sfSound_getLoop;
    alias nothrow sfSoundStatus function(const(sfSound)* sound) da_sfSound_getStatus;
    alias nothrow void function(sfSound* sound,float pitch) da_sfSound_setPitch;
    alias nothrow void function(sfSound* sound,float volume) da_sfSound_setVolume;
    alias nothrow void function(sfSound* sound,sfVector3f position) da_sfSound_setPosition;
    alias nothrow void function(sfSound* sound,sfBool relative) da_sfSound_setRelativeToListener;
    alias nothrow void function(sfSound* sound,float distance) da_sfSound_setMinDistance;
    alias nothrow void function(sfSound* sound,float attenuation) da_sfSound_setAttenuation;
    alias nothrow void function(sfSound* sound,sfTime timeOffset) da_sfSound_setPlayingOffset;
    alias nothrow float function(const(sfSound)* sound) da_sfSound_getPitch;
    alias nothrow float function(const(sfSound)* sound) da_sfSound_getVolume;
    alias nothrow sfVector3f function(const(sfSound)* sound) da_sfSound_getPosition;
    alias nothrow sfBool function(const(sfSound)* sound) da_sfSound_isRelativeToListener;
    alias nothrow float function(const(sfSound)* sound) da_sfSound_getMinDistance;
    alias nothrow float function(const(sfSound)* sound) da_sfSound_getAttenuation;
    alias nothrow sfTime function(const(sfSound)* sound) da_sfSound_getPlayingOffset;
    alias nothrow sfSoundBuffer* function(const(char)* filename) da_sfSoundBuffer_createFromFile;
    alias nothrow sfSoundBuffer* function(const(void)* data,size_t sizeInBytes) da_sfSoundBuffer_createFromMemory;
    alias nothrow sfSoundBuffer* function(sfInputStream* stream) da_sfSoundBuffer_createFromStream;
    alias nothrow sfSoundBuffer* function(const(sfInt16)* samples,size_t sampleCount,uint channelCount,uint sampleRate) da_sfSoundBuffer_createFromSamples;
    alias nothrow sfSoundBuffer* function(const(sfSoundBuffer)* soundBuffer) da_sfSoundBuffer_copy;
    alias nothrow void function(sfSoundBuffer* soundBuffer) da_sfSoundBuffer_destroy;
    alias nothrow sfBool function(const(sfSoundBuffer)* soundBuffer,const(char)* filename) da_sfSoundBuffer_saveToFile;
    alias nothrow const(sfInt16)* function(const(sfSoundBuffer)* soundBuffer) da_sfSoundBuffer_getSamples;
    alias nothrow size_t function(const(sfSoundBuffer)* soundBuffer) da_sfSoundBuffer_getSampleCount;
    alias nothrow uint function(const(sfSoundBuffer)* soundBuffer) da_sfSoundBuffer_getSampleRate;
    alias nothrow uint function(const(sfSoundBuffer)* soundBuffer) da_sfSoundBuffer_getChannelCount;
    alias nothrow sfTime function(const(sfSoundBuffer)* soundBuffer) da_sfSoundBuffer_getDuration;
    alias nothrow sfSoundBufferRecorder* function() da_sfSoundBufferRecorder_create;
    alias nothrow void function(sfSoundBufferRecorder* soundBufferRecorder) da_sfSoundBufferRecorder_destroy;
    alias nothrow void function(sfSoundBufferRecorder* soundBufferRecorder,uint sampleRate) da_sfSoundBufferRecorder_start;
    alias nothrow void function(sfSoundBufferRecorder* soundBufferRecorder) da_sfSoundBufferRecorder_stop;
    alias nothrow uint function(const(sfSoundBufferRecorder)* soundBufferRecorder) da_sfSoundBufferRecorder_getSampleRate;
    alias nothrow const(sfSoundBuffer)* function(const(sfSoundBufferRecorder)* soundBufferRecorder) da_sfSoundBufferRecorder_getBuffer;
    alias nothrow sfSoundRecorder* function(sfSoundRecorderStartCallback onStart,sfSoundRecorderProcessCallback onProcess,sfSoundRecorderStopCallback onStop,void* userData) da_sfSoundRecorder_create;
    alias nothrow void function(sfSoundRecorder* soundRecorder) da_sfSoundRecorder_destroy;
    alias nothrow void function(sfSoundRecorder* soundRecorder,uint sampleRate) da_sfSoundRecorder_start;
    alias nothrow void function(sfSoundRecorder* soundRecorder) da_sfSoundRecorder_stop;
    alias nothrow uint function(const(sfSoundRecorder)* soundRecorder) da_sfSoundRecorder_getSampleRate;
    alias nothrow sfBool function() da_sfSoundRecorder_isAvailable;
    alias nothrow sfSoundStream* function(sfSoundStreamGetDataCallback onGetData,sfSoundStreamSeekCallback onSeek,uint channelCount,int sampleRate,void* userData) da_sfSoundStream_create;
    alias nothrow void function(sfSoundStream* soundStream) da_sfSoundStream_destroy;
    alias nothrow void function(sfSoundStream* soundStream) da_sfSoundStream_play;
    alias nothrow void function(sfSoundStream* soundStream) da_sfSoundStream_pause;
    alias nothrow void function(sfSoundStream* soundStream) da_sfSoundStream_stop;
    alias nothrow sfSoundStatus function(const(sfSoundStream)* soundStream) da_sfSoundStream_getStatus;
    alias nothrow uint function(const(sfSoundStream)* soundStream) da_sfSoundStream_getChannelCount;
    alias nothrow uint function(const(sfSoundStream)* soundStream) da_sfSoundStream_getSampleRate;
    alias nothrow void function(sfSoundStream* soundStream,float pitch) da_sfSoundStream_setPitch;
    alias nothrow void function(sfSoundStream* soundStream,float volume) da_sfSoundStream_setVolume;
    alias nothrow void function(sfSoundStream* soundStream,sfVector3f position) da_sfSoundStream_setPosition;
    alias nothrow void function(sfSoundStream* soundStream,sfBool relative) da_sfSoundStream_setRelativeToListener;
    alias nothrow void function(sfSoundStream* soundStream,float distance) da_sfSoundStream_setMinDistance;
    alias nothrow void function(sfSoundStream* soundStream,float attenuation) da_sfSoundStream_setAttenuation;
    alias nothrow void function(sfSoundStream* soundStream,sfTime timeOffset) da_sfSoundStream_setPlayingOffset;
    alias nothrow void function(sfSoundStream* soundStream,sfBool loop) da_sfSoundStream_setLoop;
    alias nothrow float function(const(sfSoundStream)* soundStream) da_sfSoundStream_getPitch;
    alias nothrow float function(const(sfSoundStream)* soundStream) da_sfSoundStream_getVolume;
    alias nothrow sfVector3f function(const(sfSoundStream)* soundStream) da_sfSoundStream_getPosition;
    alias nothrow sfBool function(const(sfSoundStream)* soundStream) da_sfSoundStream_isRelativeToListener;
    alias nothrow float function(const(sfSoundStream)* soundStream) da_sfSoundStream_getMinDistance;
    alias nothrow float function(const(sfSoundStream)* soundStream) da_sfSoundStream_getAttenuation;
    alias nothrow sfBool function(const(sfSoundStream)* soundStream) da_sfSoundStream_getLoop;
    alias nothrow sfTime function(const(sfSoundStream)* soundStream) da_sfSoundStream_getPlayingOffset;
}

__gshared
{
    da_sfListener_setGlobalVolume sfListener_setGlobalVolume;
    da_sfListener_getGlobalVolume sfListener_getGlobalVolume;
    da_sfListener_setPosition sfListener_setPosition;
    da_sfListener_getPosition sfListener_getPosition;
    da_sfListener_setDirection sfListener_setDirection;
    da_sfListener_getDirection sfListener_getDirection;
    da_sfMusic_createFromFile sfMusic_createFromFile;
    da_sfMusic_createFromMemory sfMusic_createFromMemory;
    da_sfMusic_createFromStream sfMusic_createFromStream;
    da_sfMusic_destroy sfMusic_destroy;
    da_sfMusic_setLoop sfMusic_setLoop;
    da_sfMusic_getLoop sfMusic_getLoop;
    da_sfMusic_getDuration sfMusic_getDuration;
    da_sfMusic_play sfMusic_play;
    da_sfMusic_pause sfMusic_pause;
    da_sfMusic_stop sfMusic_stop;
    da_sfMusic_getChannelCount sfMusic_getChannelCount;
    da_sfMusic_getSampleRate sfMusic_getSampleRate;
    da_sfMusic_getStatus sfMusic_getStatus;
    da_sfMusic_getPlayingOffset sfMusic_getPlayingOffset;
    da_sfMusic_setPitch sfMusic_setPitch;
    da_sfMusic_setVolume sfMusic_setVolume;
    da_sfMusic_setPosition sfMusic_setPosition;
    da_sfMusic_setRelativeToListener sfMusic_setRelativeToListener;
    da_sfMusic_setMinDistance sfMusic_setMinDistance;
    da_sfMusic_setAttenuation sfMusic_setAttenuation;
    da_sfMusic_setPlayingOffset sfMusic_setPlayingOffset;
    da_sfMusic_getPitch sfMusic_getPitch;
    da_sfMusic_getVolume sfMusic_getVolume;
    da_sfMusic_getPosition sfMusic_getPosition;
    da_sfMusic_isRelativeToListener sfMusic_isRelativeToListener;
    da_sfMusic_getMinDistance sfMusic_getMinDistance;
    da_sfMusic_getAttenuation sfMusic_getAttenuation;
    da_sfSound_create sfSound_create;
    da_sfSound_copy sfSound_copy;
    da_sfSound_destroy sfSound_destroy;
    da_sfSound_play sfSound_play;
    da_sfSound_pause sfSound_pause;
    da_sfSound_stop sfSound_stop;
    da_sfSound_setBuffer sfSound_setBuffer;
    da_sfSound_getBuffer sfSound_getBuffer;
    da_sfSound_setLoop sfSound_setLoop;
    da_sfSound_getLoop sfSound_getLoop;
    da_sfSound_getStatus sfSound_getStatus;
    da_sfSound_setPitch sfSound_setPitch;
    da_sfSound_setVolume sfSound_setVolume;
    da_sfSound_setPosition sfSound_setPosition;
    da_sfSound_setRelativeToListener sfSound_setRelativeToListener;
    da_sfSound_setMinDistance sfSound_setMinDistance;
    da_sfSound_setAttenuation sfSound_setAttenuation;
    da_sfSound_setPlayingOffset sfSound_setPlayingOffset;
    da_sfSound_getPitch sfSound_getPitch;
    da_sfSound_getVolume sfSound_getVolume;
    da_sfSound_getPosition sfSound_getPosition;
    da_sfSound_isRelativeToListener sfSound_isRelativeToListener;
    da_sfSound_getMinDistance sfSound_getMinDistance;
    da_sfSound_getAttenuation sfSound_getAttenuation;
    da_sfSound_getPlayingOffset sfSound_getPlayingOffset;
    da_sfSoundBuffer_createFromFile sfSoundBuffer_createFromFile;
    da_sfSoundBuffer_createFromMemory sfSoundBuffer_createFromMemory;
    da_sfSoundBuffer_createFromStream sfSoundBuffer_createFromStream;
    da_sfSoundBuffer_createFromSamples sfSoundBuffer_createFromSamples;
    da_sfSoundBuffer_copy sfSoundBuffer_copy;
    da_sfSoundBuffer_destroy sfSoundBuffer_destroy;
    da_sfSoundBuffer_saveToFile sfSoundBuffer_saveToFile;
    da_sfSoundBuffer_getSamples sfSoundBuffer_getSamples;
    da_sfSoundBuffer_getSampleCount sfSoundBuffer_getSampleCount;
    da_sfSoundBuffer_getSampleRate sfSoundBuffer_getSampleRate;
    da_sfSoundBuffer_getChannelCount sfSoundBuffer_getChannelCount;
    da_sfSoundBuffer_getDuration sfSoundBuffer_getDuration;
    da_sfSoundBufferRecorder_create sfSoundBufferRecorder_create;
    da_sfSoundBufferRecorder_destroy sfSoundBufferRecorder_destroy;
    da_sfSoundBufferRecorder_start sfSoundBufferRecorder_start;
    da_sfSoundBufferRecorder_stop sfSoundBufferRecorder_stop;
    da_sfSoundBufferRecorder_getSampleRate sfSoundBufferRecorder_getSampleRate;
    da_sfSoundBufferRecorder_getBuffer sfSoundBufferRecorder_getBuffer;
    da_sfSoundRecorder_create sfSoundRecorder_create;
    da_sfSoundRecorder_destroy sfSoundRecorder_destroy;
    da_sfSoundRecorder_start sfSoundRecorder_start;
    da_sfSoundRecorder_stop sfSoundRecorder_stop;
    da_sfSoundRecorder_getSampleRate sfSoundRecorder_getSampleRate;
    da_sfSoundRecorder_isAvailable sfSoundRecorder_isAvailable;
    da_sfSoundStream_create sfSoundStream_create;
    da_sfSoundStream_destroy sfSoundStream_destroy;
    da_sfSoundStream_play sfSoundStream_play;
    da_sfSoundStream_pause sfSoundStream_pause;
    da_sfSoundStream_stop sfSoundStream_stop;
    da_sfSoundStream_getStatus sfSoundStream_getStatus;
    da_sfSoundStream_getChannelCount sfSoundStream_getChannelCount;
    da_sfSoundStream_getSampleRate sfSoundStream_getSampleRate;
    da_sfSoundStream_setPitch sfSoundStream_setPitch;
    da_sfSoundStream_setVolume sfSoundStream_setVolume;
    da_sfSoundStream_setPosition sfSoundStream_setPosition;
    da_sfSoundStream_setRelativeToListener sfSoundStream_setRelativeToListener;
    da_sfSoundStream_setMinDistance sfSoundStream_setMinDistance;
    da_sfSoundStream_setAttenuation sfSoundStream_setAttenuation;
    da_sfSoundStream_setPlayingOffset sfSoundStream_setPlayingOffset;
    da_sfSoundStream_setLoop sfSoundStream_setLoop;
    da_sfSoundStream_getPitch sfSoundStream_getPitch;
    da_sfSoundStream_getVolume sfSoundStream_getVolume;
    da_sfSoundStream_getPosition sfSoundStream_getPosition;
    da_sfSoundStream_isRelativeToListener sfSoundStream_isRelativeToListener;
    da_sfSoundStream_getMinDistance sfSoundStream_getMinDistance;
    da_sfSoundStream_getAttenuation sfSoundStream_getAttenuation;
    da_sfSoundStream_getLoop sfSoundStream_getLoop;
    da_sfSoundStream_getPlayingOffset sfSoundStream_getPlayingOffset;
}