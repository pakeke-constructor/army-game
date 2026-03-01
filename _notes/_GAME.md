

# Tetris-Roguelike Deckbuilder Game:

Plays like tetris. 
However, you edit your "deck of pieces" over time, which is bunch of tetris-pieces.
- (take inspiration from deckbuilder mechanics)

upgrade your blocks, get new blocks, get crazier upgrades, do combos, create synergies.

See https://store.steampowered.com/app/3908810/Stackflow/ as a (poorly made) example





## GAME LOOP:
- Play tetris level, until placed the required number of pieces. (pieces speed up over time)
- Once complete => Receive rewards from level (see Level-Select)
- Then, enter shop. Buy/upgrade stuff
- Choose a new level. (See Level-Select). REPEAT FROM STEP-1.



## Currencies:
The idea is to have 3 currencies:
- Red currency
- Blue currency
- Green currency
(I'll explain why below)



## Pieces and Blocks:
"Pieces" are the things that fall down on the screen. 
Can be L shaped, Plus-shaped, etc.

Pieces are made out of multiple blocks.
eg:
```
[ ][ ][ ]
      [ ]
```
or
```
[ ][ ]
   [ ][ ]
```
```lua
Piece = {
    blocks = {(x,y) = Block}, -- map of block positions
    rotation = 0 or 1 or 2 or 3
}
```


## Blocks:
Blocks are seperate objects.

They have color, sigil, and material.
can be 3 different colors: RED, BLUE, or GREEN.

When a block is destroyed, it *earns* the currency of whatever color it is.
(Eg: 3 red-blocks destroyed will earn +3 RED currency)

```lua
Block = {
    sigil = SigilType,
    color = "RED" or "BLUE" or "GREEN",
    material = MaterialType
}
```

### Blocks: (Materials)
Block-materials are like little simple "modifiers" to blocks.
(Most blocks have `block.material = Normal`)
eg:
```
normal: (default, does nothing)
sand: this block will fall down to ground
stone: this block cannot be rotated
shiny: this block earns x3 resources
shiny: this block earns x3 resources
```
Generally, block-materials should be SIMPLE and MINIMAL.


### Blocks: (Sigils)
Block-sigils are like the ultra-special sauce for this game.  
It's essentially just a little decal on top of blocks, that cause additional effects.
(Most blocks have `block.sigil = nil`)

Sigils can have *CRAZY* effects; should be something the player focuses a lot on.
eg:
```
bomb: when destroyed, destroy all blocks above this block
paintbrush: on landing, convert all blocks to the same color as this block
desert-eye: on landing, convert all blocks in a 5x5 radius to sand
filler: when destroyed, fill in a random hole that can't be accessed
anchor: whilst this block is on the board, [COLOR] currency cannot go below 1
ghoul: convert the next piece to a ghostly-piece
cross: when destroyed, if this block is the only [COLOR] piece in the row, earns 20x points.
nuke: when destroyed, if this block is the only [COLOR] piece in the row, destroy EVERY block.
skull: when destroyed, if this block is the only [COLOR] piece in the row, destroy EVERY block.
jinx: on landing, the next piece becomes a 1x1 single block
debt: Adds +10 [COLOR] when destroyed, but costs 1 [COLOR] every turn it's on the board
veteran: Earns +1 bonus currency for every [COLOR] piece in your deck. (currently X)
```



- Tetris-area is made "wider" over time. (eg starts 5 wide -> becomes 12 wide lategame)

- players should be able to to modify individual pieces. Like adding a red block to a piece















## VISUAL STYLE:
Casual pixelart, dull color-palette, (similar to SNKRX, or Tiny-Rogues)

For juice/animations,
- try to use render primitives
- make animations sharp and quick. E.g. spawn circle for 0.1 seconds. (looks really good)



## Level-select (Bounty Board)
Procedurally generated levels, each with a unique risk/reward profile.
Three "wanted" posters on a board. Each has codename, a reward, and modifier fine-print.
(Middle poster is default => generally easiest/most normal)
### Level Examples:
- LV-ALFA: +$20, slow speed, all RED blocks disabled
- LV-BRAVO: 2 rare perks, medium speed
- LV-CHARLIE: +$100, fast speed, blue blocks earn double

Nuance in the modifiers makes level choice meaningful.
Adds risk/reward: e.g. player might think:
"Hmm, I could go to the hard-level, and get an amazing reward... but I might lose"









