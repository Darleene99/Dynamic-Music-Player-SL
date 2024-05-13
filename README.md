
# Dynamic Music Player for Second Life

This project is a script for a dynamic music player in Second Life. It allows you to play sound clips from a notecard with proper synchronization, regardless of the length of the song.


## Installation

1. Create a prims (or import a mesh)
2. Drop the "dynamic-music-player.lsl" script into your SL object
3. Drop notecard sample that you can find in the folder "notecard-sample"
4. Click your object and enjoy the synchronized playback of your music clips!



## Features

- Plays sound clips from a notecard
- Supports varying clip lengths specified in the notecard
- Can be used to create and sell your own products under the MIT license
- Reselling the script without modification is not allowed



## Notecard Format

The notecard should follow the float length of the clip on the first line, followed by the UUIDs of the songs. Each line represents a separate clip.

Example:
```
17.5
6cc66d20-d63a-3a68-b360-5d225e2a9b32
51efc5cf-8f06-6cb0-f204-e3700123bfc0
ad61d27e-688b-e2a5-f352-441b8f8454da
2a7b2c3c-d59a-335b-f1b0-3edf84f9abd5
1af2ad74-17c0-9ed2-c9d4-838659df4d2f
1ff02266-12ea-867d-4096-f425b9859b72
4bdd1f12-d8d4-2c4c-1e80-299ce4e7e9c6
572cc7bb-9ec7-18c3-19f7-161bdc2eb4bd
132c577d-2b25-8cc3-e6e0-68dd33d049c4
00fd0756-43ac-f9be-0493-8dadda65ff81
...
```

## Credits

- Special thanks to Liam Hoffen For debugging, Fixing the bean, fighting and taming the dragon of 7 heads!
- Thanks to Bleuhazenfurfle for implementing llQueueSound
- Thanks to Qie Niangao for the victory declaration
- Thanks to Dimitry for sharing his work
- Thanks to Darleene also.. for doing Darleene stuff


## Next Steps

There are a few additional features and improvements planned for the future:

- Needs song time calculation count time 
- Added llsettext for playing or stopping songs 👍 👍 👍 07/02/24
- New Fix "hacks" working in no-script places aswell 👍 👍 👍 31/12/23
- Add loop/play all songs function
- Add particles on start (beauty)👍 👍 👍 fixed 06/02/24
- Add randomizer of channels 👍 👍 👍 fixed 04/02/24
- Implement a Bigger LLdialog menu  👍 👍 👍 12/02/24 it was there actually
- Create sorting list of categories instead of exhaustive paging as neppingway described

## License

This project is licensed under the MIT License. You are free to use it to create and sell your own products, but the script itself cannot be resold without further strong modifications.


#
One thousand people has learn how to upload music and create their own instruments.
Create a script copy paste the Dynamic Music Player and enjoy
