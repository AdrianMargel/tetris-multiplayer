/*
  Tetris COOP
  -----------
  This is a two player game of tetris. This also supports tetris bots as well although they are currently turned off.
  It is also possible to add or remove players however most keyboards can't handle inputs from more than 2 people at a time.

  Controls:
    Player 1 - WASD
    Player 2 - arrow keys
    Press space to reset after death
    
  
  written by Adrian Margel, Spring 2017
*/



class Player {
  //the block the player is controlling
  Block block;
  //the color of the player's blocks
  int hue;

  //timer affects how fast all blocks will fall
  int timer=0;
  //timer W is how fast blocks will fall when the W key is held (or equivalent up key)
  int tW=0;
  //Timer Control affects how fast a player can move
  int tC=0;
  //Timer D affects how much faster blocks fall when holding the D key (or equivalent down key)
  int tD=0;
  
  //if it is being controlled by a player or an ai
  boolean isBot;

  //the position the blocks will spawn at
  int spawnX;
  int spawnY;
  
  Player(boolean isBot, int hue) {
    this.isBot=isBot;
    this.hue=hue;
    reset();
    setSpawn(wide/2, 1);
  }

  //sets the player to have no blocks falling
  void reset() {
    block= null;
  }

  //set the position of where the blocks will fall from
  void setSpawn(int x, int y) {
    spawnX=x;
    spawnY=y;
  }

  //move player's blocks using booleans to control the block
  void run(boolean moveUp, boolean moveLeft, boolean moveDown, boolean moveRight, Tile[][] map) {

    //if there is no block spawn a new block
    if (block==null) {
      block=new Block(spawnX, spawnY, (int)random(1, 8), hue);
    }

    //count down timers
    timer--;
    tW--;
    tC--;
    tD--;
    
    //if any of the control linked timers are at 0 then allow inputs through
    
    //rotate
    if (tW<=0) {
      if (moveUp) {
        tW=RSensitivity;
        block.rot();
      }
    }
    //move side to side and or down
    if (tC<=0) {
      if (moveLeft) {
        tC=sensitivity;
        block.move(-1);
      }
      if (moveRight) {
        tC=sensitivity;
        block.move(1);
      }
      if (moveDown) {
        tC=sensitivity;
        block.moveDown();
      }
    }
    //the extra speed gained while falling
    //moving down gets a boost on top of the normal control speed
    if (tD<=0) {
      if (moveDown) {
        tD=FSensitivity;
        block.moveDown();
      }
    }
    
    //blocks free falling
    if (timer<=0) {
      timer=speed;
      block.moveDown();
    }
    
    //if the block has hit the ground place the block
    if (block.hit) {
      block.flip(map);
      block=null;
      //slightly change the hue every block placed
      hue=(hue+1)%256;
    }
  }

  //run method specifically used for bots
  //it gives the player inputs to let it see the current game map and other players
  void run(Tile[][] map, ArrayList<Player> ps) {
    //if it is a bot and is in control of a block
    if (isBot&&block!=null) {
      Block tester;

      int moveX=0;
      int moveRot=0;

      //space score
      //the number of empty tiles under the target block placement
      int bestSScore=Integer.MAX_VALUE;
      //height score
      //how high up the target is
      int bestHScore=-1;
      //width score
      //how far away the target is in terms of x position
      int bestWScore=Integer.MAX_VALUE;

      //calculate the max range the tile can reach based on control speeds
      int y=block.y;
      int distY=high-block.y;
      int range=distY*speed/sensitivity;
      
      //for all the positions in range
      for (int x=max(0, block.x-range); x<min(map.length, block.x+range); x++) {
        
        //setup temporary best scores
        int tempBestS=Integer.MAX_VALUE;
        int tempBestH;
        int tempBestW=Integer.MAX_VALUE;

        //create a test block to put in the target spot
        tester=new Block(block);
        tester.x=x;

        //get the space score for this test
        //this will also update the y pos of the tester to the ground
        tempBestS=testBlock(tester, map);

        //get the height score for this test
        tempBestH=Integer.MAX_VALUE;
        for (BTile bt : tester.ref) {
          tempBestH=min(bt.y+tester.y, tempBestH);
        }

        //get the space width for this test
        tempBestW=abs(tester.x-block.x);

        //if the target position is reachable from the current one based on control speeds
        if (abs((tester.y-block.y)*speed/sensitivity)>abs(tester.x-block.x)) {
          
          //check if the score is better than the current best, if it is set this as the best move
          //prioritize finding best space score
          if (tempBestS<bestSScore) {
            bestSScore=tempBestS;
            bestHScore=tempBestH;
            bestWScore=tempBestW;
            moveRot=0;
            moveX=tester.x-block.x;
            
          } else if (tempBestS==bestSScore) {
            //next prioritize finding best height score
            if (tempBestH>bestHScore) {
              bestSScore=tempBestS;
              bestHScore=tempBestH;
              bestWScore=tempBestW;
              moveRot=0;
              moveX=tester.x-block.x;
            } else if (tempBestH==bestHScore) {
              //finally prioritize finding best width score
              if (tempBestW<bestWScore) {
                bestSScore=tempBestS;
                bestHScore=tempBestH;
                bestWScore=tempBestW;
                moveRot=0;
                moveX=tester.x-block.x;
              }
            }
          }
          
          //if the block can rotate repeat the testing process for the other 3 rotations
          //this is calculated after the first test to prevent needing to test if a block is in range 4 times
          //this may lead to slight misscalculations when testing tiles at the edge of the bounds but overall is a minor issue
          if (tester.canRotate) {
            for (int i=0; i<3; i++) {
              //reset pos
              tester.x=x;
              tester.y=y;
              //rotate
              tester.rot();

              //redo all the calculations done previously on the unrotated tester block
              
              tempBestS=testBlock(tester, map);

              tempBestH=Integer.MAX_VALUE;
              for (BTile bt : tester.ref) {
                tempBestH=min(bt.y+tester.y, tempBestH);
              }

              tempBestW=abs(tester.x-block.x);

              if (tempBestS<bestSScore) {
                bestSScore=tempBestS;
                bestHScore=tempBestH;
                bestWScore=tempBestW;
                moveRot=i+1;
                moveX=tester.x-block.x;
              } else if (tempBestS==bestSScore) {
                if (tempBestH>bestHScore) {
                  bestSScore=tempBestS;
                  bestHScore=tempBestH;
                  bestWScore=tempBestW;
                  moveRot=i+1;
                  moveX=tester.x-block.x;
                } else if (tempBestH==bestHScore) {
                  if (tempBestW<bestWScore) {
                    bestSScore=tempBestS;
                    bestHScore=tempBestH;
                    bestWScore=tempBestW;
                    moveRot=i+1;
                    moveX=tester.x-block.x;
                  }
                }
              }
            }
          }
        }
      }
      boolean bW=moveRot>0;
      boolean bA=false;
      boolean bS=false;
      boolean bD=false;
      if (moveX>0) {
        bD=true;
      } else if (moveX<0) {
        bA=true;
      } else {
        boolean overlap=false;
        for (Player p : ps) {
          if (p!=this&&block!=null&&p.block!=null&&p.block.y>block.y) {
            int minX=Integer.MAX_VALUE;
            int maxX=Integer.MIN_VALUE;
            for (BTile bt : p.block.ref) {
              minX=min(bt.x+p.block.x, minX);
              maxX=max(bt.x+p.block.x, maxX);
            }
            for (BTile bt : block.ref) {
              int tempX=bt.x+block.x;
              if (tempX>=minX&&tempX<=maxX) {
                overlap=true;
              }
            }
          }
        }
        bS=!overlap;
      }
      run(bW, bA, bS, bD, map);
    } else {
      //if this method is run on a player not controlled by a bot then run without moving
      //or if no block exists then run to spawn a new block
      run(false, false, false, false, map);
    }
  }
  
  //get the score for a potential block position
  int testBlock(Block b, Tile[][] map) {
    for (int i=0; i<b.ref.size(); i++) {
      if (b.ref.get(i).x+b.x>=wide||b.ref.get(i).x+b.x<0) {
        return Integer.MAX_VALUE;
      }
    }
    b.hit=false;
    int spaceScore=0;
    while (!b.hit) {
      b.moveDown();
    }
    for (BTile bt : b.ref) {
      int btx=bt.x+b.x;
      int bty=bt.y+b.y+1;
      
      mainWhile:
      while (bty<high) {
        for (BTile bt2 : b.ref) {
          if (bt2.x+b.x==btx&&bt2.y+b.y==bty) {
            break mainWhile;
          }
        }
        if (map[btx][bty].value==1)
          break mainWhile;

        //fill(255,50);
        //rect((btx)*zoom, (bty)*zoom, zoom, zoom);
        spaceScore++;
        bty++;
      }
    }
    return spaceScore;
  }
  
  //display the player's falling block
  void display() {
    if (block!=null) {
      block.display();
    }
  }
}

//player controlled unplaced tetris blocks
class Block {

  //if it can be rotated
  boolean canRotate;
  //if it has hit the ground
  boolean hit=false;
  //position
  int x, y;
  //the color of the block
  int hue;

  //the tiles it is made up of (its shape)
  ArrayList<BTile> ref=new ArrayList<BTile>();

  //clone block off a template
  Block (Block b) {
    y=b.y;
    x=b.x;
    hue=b.hue;
    for (BTile bt : b.ref) {
      ref.add(new BTile(bt.x, bt.y));
    }
    canRotate=b.canRotate;
  }
  
  //create block based on an id (type)
  Block(int tx, int ty, int type, int th) {
    //set position
    x=tx;
    y=ty;
    //set color
    hue=th;
    
    //create the block based on the type it is
    //each number is a different tetris block
    if (type==1) {
      ref.add(new BTile(0, 0));
      ref.add(new BTile(0, 1));
      ref.add(new BTile(1, 1));
      ref.add(new BTile(0, -1));
      canRotate=true;
    } else if (type==2) {
      ref.add(new BTile(0, 0));
      ref.add(new BTile(0, 1));
      ref.add(new BTile(1, -1));
      ref.add(new BTile(0, -1));
      canRotate=true;
    } else if (type==3) {
      ref.add(new BTile(0, 0));
      ref.add(new BTile(0, 1));
      ref.add(new BTile(1, 1));
      ref.add(new BTile(1, 0));
      canRotate=false;
    } else if (type==4) {
      ref.add(new BTile(0, -1));
      ref.add(new BTile(0, 0));
      ref.add(new BTile(0, 1));
      ref.add(new BTile(0, 2));
      canRotate=true;
    } else if (type==5) {
      ref.add(new BTile(0, 0));
      ref.add(new BTile(0, 1));
      ref.add(new BTile(1, 1));
      ref.add(new BTile(-1, 0));
      canRotate=true;
    } else if (type==6) {
      ref.add(new BTile(0, 0));
      ref.add(new BTile(0, 1));
      ref.add(new BTile(-1, 1));
      ref.add(new BTile(1, 0));
      canRotate=true;
    } else if (type==7) {
      ref.add(new BTile(0, 0));
      ref.add(new BTile(0, -1));
      ref.add(new BTile(1, 0));
      ref.add(new BTile(-1, 0));
      canRotate=true;
    }
  }

  void display() {
    //display all the tiles it is made up of
    for (int i=0; i<ref.size(); i++) {
      ref.get(i).display(hue, x, y);
    }
  }

  void rot() {
    //if it can rotate rotate the block
    if (canRotate) {
      //check if rotating will hit something
      boolean canMove=true;
      for (int i=0; i<ref.size(); i++) {
        if (-ref.get(i).y+x>=wide||-ref.get(i).y+x<0||ref.get(i).x+y>=high||ref.get(i).x+y<0) {
          canMove=false;
        } else {
          if (tiles[-ref.get(i).y+x][ref.get(i).x+y].value==1) {
            canMove=false;
          }
        }
      }

      //if there is space to rotate then rotate
      if (canMove) {
        for (int i=0; i<ref.size(); i++) {
          int temp=ref.get(i).x;
          ref.get(i).x=-ref.get(i).y;
          ref.get(i).y=temp;
        }
      }
    }
  }

  void move(int amount) {
    //test if it will hit anything by moving horizontally
    boolean canMove=true;
    for (int i=0; i<ref.size(); i++) {
      if (ref.get(i).x+x+amount>=wide||ref.get(i).x+x+amount<0) {
        canMove=false;
      } else if (ref.get(i).y+y>=0) {
        if (tiles[ref.get(i).x+x+amount][ref.get(i).y+y].value==1) {
          canMove=false;
        }
      }
    }
    //if there is space then move horizontally
    if (canMove) {
      x+=amount;
    }
  }

  void moveDown() {
    //test if there is space to fall down
    boolean canMove=true;
    for (int i=0; i<ref.size(); i++) {
      if (ref.get(i).y+y+1>=high) {
        canMove=false;
      } else if (ref.get(i).y+y+1>=0&&ref.get(i).x+x>=0&&ref.get(i).x+x<wide) {
        if (tiles[ref.get(i).x+x][ref.get(i).y+y+1].value==1) {
          canMove=false;
        }
      }
    }

    //if there is space move down
    if (canMove) {
      y+=1;
    } else {
      //if there is not space then set hit to true to say the ground has been hit
      hit=true;
    }
  }

  void flip(Tile[][] map) {
    //flip the tiles from the player controled tetris block to the game's placed tiles
    for (int i=0; i<ref.size(); i++) {
      map[ref.get(i).x+x][ref.get(i).y+y].value=1;
      map[ref.get(i).x+x][ref.get(i).y+y].hue=hue;
    }
  }
}

//these are tiles unplaced tetris blocks are made up of
class BTile {
  //position
  int x, y;

  BTile(int tx, int ty) {
    x=tx;
    y=ty;
  }

  void display(int hue, int BX, int BY) {
    fill(hue, 255, 255);
    rect((x+BX)*zoom, (y+BY)*zoom, zoom, zoom);
  }
}

//the placed tetris blocks
class Tile {

  //if the tile is filled (0 or 1)
  //this uses an integer rather than a boolean in case new tile types want to be added in the future
  int value;
  //the color of the tile
  int hue=0;

  Tile() {
    //set tile to unfilled by default
    value=0;
  }

  void display(int x, int y) {
    stroke(50);
    fill(hue, value*255, value*255);
    rect(x*zoom, y*zoom, zoom, zoom);
  }
}

//the game's placed tiles
Tile[][] tiles;

//the players and bots
ArrayList<Player> players=new ArrayList<Player>();
ArrayList<Player> bots=new ArrayList<Player>();

//if the game has been lost yet
boolean gameOver=false;
//the number of rows cleared by the players
int score=0;

//how fast the blocks fall
int speed=10;

//how fast the blocks can be moved by the player
//general movement speed
int sensitivity=5;
//rotation speed
int RSensitivity=10;
//fall speed when pressing down
int FSensitivity=8;

//text font
PFont font;

//defines the scale of the game and zoom of the display
float zoom=25;
//the game size
int high;
int wide;

int[][] history;

void setup() {
  //framerate is set to 60 to make it easier to see what is going on
  //in testing it would generally max out around 300 so feel free to increase it
  frameRate(60);
  
  //setup fonts
  font = createFont("arial", 32);
  textFont(font);
  textAlign(CENTER);

  //setup display settings
  noSmooth();
  colorMode(HSB);

  //set window size
  size(1200, 800);

  //setup the game
  //set size
  wide=(int)(width/zoom);
  high=(int)(height/zoom);
  
  //initialize array
  tiles=new Tile[wide][high];
  for (int x=0; x<tiles.length; x++) {
    for (int y=0; y<tiles[x].length; y++) {
      tiles[x][y]=new Tile();
    }
  }
  
  //add players/bots
  players.add(new Player(false, 30));
  players.add(new Player(false, 140));

  int botsNum=0;
  for (int i=0; i<botsNum; i++) {
    bots.add(new Player(true, 0));
    bots.get(i).setSpawn(wide*i/botsNum+wide/botsNum/2, 1);
  }

  //setup an array to hold the history of the rows completed
  //this makes an interesting pattern when displayed but is mainly just for debugging
  history=new int[wide][height];
  for (int x=0; x<history.length; x++) {
    for (int y=0; y<history[x].length; y++) {
      history[x][y]=-1;
    }
  }
}

void draw() {
  //display all tiles
  for (int x=0; x<tiles.length; x++) {
    for (int y=0; y<tiles[x].length; y++) {
      tiles[x][y].display(x, y);
    }
  }
  //run game
  if (gameOver) {
    //if game was lost display game over text
    fill(255);
    text("GAME OVER", width/2, height/2);
  } else {
    //if game is not over

    //turn off stroke
    noStroke();

    //test if game has been lost
    for (int x=0; x<tiles.length; x++) {
      //for all tiles test if a tetris block has been placed at the top of the screen
      if (tiles[x][1].value==1) {
        //if a tile has been placed at the top of the screen trigger the game over screen
        gameOver=true;
      }
    }

    //run the players
    players.get(0).run(WDown,ADown,SDown,DDown,tiles);
    players.get(1).run(Up,Left,Down,Right,tiles);

    //this removes rows that are completed
    //do for all rows starting at the bottom
    for (int h=high-1; h>=0; h--) {

      //set a variable to keep track of the number of blocks in a row
      int temp=0;

      //for all tiles in the row check if they are filled
      for (int x=0; x<tiles.length; x++) {
        //if the tile are filled add one to the temp variable
        if (tiles[x][h].value==1) {
          temp++;
        }
      }

      //if the row is filled delete the row and increment the score
      if (temp==wide) {
        for (int x=0; x<history.length; x++) {
          for (int y=history[x].length-1; y>0; y--) {
            history[x][y]=history[x][y-1];
          }
        }
        for (int x=0; x<tiles.length; x++) {
          history[x][0]=tiles[x][h].hue;
        }
        //increment the score
        score++;
        //move all the rows above down by one
        for (int h2=h; h2>=0; h2--) {
          for (int x=0; x<tiles.length; x++) {
            if (h2>=1) {
              //set tile to the row above it
              tiles[x][h2].value=tiles[x][h2-1].value;
              tiles[x][h2].hue=tiles[x][h2-1].hue;
            } else {
              //if the row doesn't have a row above it clear it
              tiles[x][h2].value=0;
            }
          }
        }
      }
    }

    //display everything

    for (Player p : bots) {
      p.display();
    }

    for (Player p : players) {
      p.display();
    }
  }
  //display score
  fill(255);
  text(score, width/2, 50);

  /*
  //this code will draw the row history in the top right
  //cool as it is it also will slow the framerate
   for (int x=0; x<history.length; x++) {
   for (int y=0; y<history[x].length; y++) {
   if (history[x][y]==-1)
   break;
   fill(history[x][y], 255, 255);
   noStroke();
   rect(x, y, 1, 1);
   }
   }*/
}

//this is all very boring stuff to do with keeping track of the keys pressed
boolean WDown=false;
boolean ADown=false;
boolean SDown=false;
boolean DDown=false;
boolean Up=false;
boolean Left=false;
boolean Right=false;
boolean Down=false;
void keyPressed() {
  //restart game when space is pressed if game is over
  if (gameOver) {
    score=0;
    if (key==' ') {
      gameOver=false;
      for (int x=0; x<tiles.length; x++) {
        for (int y=0; y<tiles[x].length; y++) {
          tiles[x][y]=new Tile();
        }
      }
      for (Player p : players) {
        p.reset();
      }
    }
  } else {
    if (key=='W'||key=='w') {
      WDown=true;
    }
    if (key=='A'||key=='a') {
      ADown=true;
    }
    if (key=='S'||key=='s') {
      SDown=true;
    }
    if (key=='D'||key=='d') {
      DDown=true;
    }
    if (keyCode == UP) {
      Up=true;
    }
    if (keyCode == LEFT) {
      Left=true;
    }
    if (keyCode == RIGHT) {
      Right=true;
    }
    if (keyCode == DOWN) {
      Down=true;
    }
  }
}
void keyReleased() {
  if (key=='W'||key=='w') {
    WDown=false;
  }
  if (key=='A'||key=='a') {
    ADown=false;
  }
  if (key=='S'||key=='s') {
    SDown=false;
  }
  if (key=='D'||key=='d') {
    DDown=false;
  }
  if (keyCode == UP) {
    Up=false;
  }
  if (keyCode == LEFT) {
    Left=false;
  }
  if (keyCode == RIGHT) {
    Right=false;
  }
  if (keyCode == DOWN) {
    Down=false;
  }
}

void mousePressed() {
  //this will allow clicking to place blocks on screen
  //tiles[(int)(mouseX/zoom)][(int)(mouseY/zoom)].value=1;
}
