# tsundoku

> [tsundoku](https://en.wikipedia.org/wiki/Tsundoku) - 積ん読
>
> acquiring reading materials but letting them pile up in one's home without reading them. It is also used to refer to books ready for reading later when they are on a bookshelf.

A simple flutter app to make a record and save all the data of your physical books into one organized view. Add the details of your physical books, current reading status, and reading hours history to clearly see how much have you been reading in a day, in a week, in a month, in a year, or in forever.

The old forked design was too complicated to maintain after upgrading to flutter 3.0 (null safety confusing as heck), so I created a new one from scratch. Plus, this one I've decided to implement the use of SQLite from the get go as well, and starting it again bit by bit, one feature at a time.

## Screenshot
I'll put one later if I remember.

## Download
Soon.

## Does it work?
- 31/7/2021 - Proof of concept stage. At this point, it's all just purely visuals and dummy data, thanks to design forked from [JideGuru](https://github.com/JideGuru).
- 4/8/2023 - I remembered again that I got this side project. Continuing the original code was confusing as heck after I upgrade to flutter 3.0, so here's a restart. Thanks to [kindacode.com](https://www.kindacode.com/article/flutter-sqlite/) for guide on using sqflite, that was the base code that I use in this round of refresh.

Current planned features is to make it so the user will be able to record all their physical books into this app - with basic details of the book such as title, author, book series, and book summary. Also, user will be able to add in their reading history of each books, and those data will be visualized in graph to make it easier to know how many hours have they been spent reading in a period of time.

## Incoming features
- Add book record into app - title, book cover, author, book series, book summary, ISBN info, etc.
- Include image (book cover) in the book record
- Reading history + graph
- Push notification, for guilt trip user on how many books they still haven't finish read yet

## Where's the project came from?
I got so many physical books, so I wanna keep track of what I already bought, and to guilt trip myself by knowing exactly how many of those have I not finish reading yet. Having the digital record of it makes this easier for me. 

Also, I'm experimenting with Flutter and Dart, hopefully to understand more about mobile app development process, and advancing towards mobile app devs role from my current webapp devs professionally. 

## Versioning note (pubspec.yaml)
- 0.1.0 - 4/8/2023 - initial code.
- 0.1.1 - 4/8/2023 - update db table structure (add book status).
- 0.1.2 - 5/8/2023 - update db table structure (add date of purchase).
- 0.1.3 - 5/8/2023 - words capitalization for keyboard in title and author field.

## ..other notes
Thanks [JideGuru](https://github.com/JideGuru) for the awesome GUI base code. Code was cool, but converting to null safety is confusing. Still, thanks for the code, that pushed me to start doing this app that I've been imagining for so long.

- 31/7/2021 - first Malaysia medal in Olympics Tokyo 2020 achieved. Thank you Aaron Chia/Soh Wooi Yik for the bronze! More to come, definitely.
- 4/8/2023 - China 1-5 Malaysia hockey.