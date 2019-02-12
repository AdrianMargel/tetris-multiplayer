# Tetris Multiplayer
A multiplayer version of tetris including AI to play automatically
![tetris bots](https://i.imgur.com/elqNFoH.png)

This program is a basic tetris program with a twist - it supports any number of players. It's basically a co-opertive version of tetris between two players although more can be coded in. I later saw this program as a great oppertuninty to create a heuristic artificial intelligence to play the game and now it now can support an infinite number of bot players as well!

This repository contains two verisons of the program that are otherwise identical:
- **tetris_bots** is set up with a number of AI bots by default for those who are interested in the AI side of things.
- **tetris_coop** is set up as a two player coop game for those interested in playing the game.

Although the bots are not perfect I learned a lot building them, I was very surprised to find simple heuristics were able to work so well to solve such a complex problem. I've run many tests with the bots and have found that as long as they are given enough space per bot they are able to go on playing almost indefinitely. I've done various tests that lasted over 10,000 rows before I shut down the program.

The code was written spring 2017

## Heuristic AI
In a nutshell the AI works by looking for a spot to put its block that:
- is close enough to reach
- will cover up the least empty tiles
- is lowest on the screen
- is the minimum horizontal distance away from it's current position

By prioratizing these heuristics in the listed order it is able to find good positions for placing blocks. After identifying the best position it will move to it and if there is no other bot under it it will press down to make the block quickfall into place. If there is a bot under it it will wait until the other bot has placed its block before quickfalling - they reduces conflicts between bots as they cannot directly communicate.

