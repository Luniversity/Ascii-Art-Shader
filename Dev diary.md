# Ascii Art Shader

### Day 0 - So how do we do this

Turning an image into ASCII sounds simple at first. Lets say each symbol is 8x8 pixels large. We divide up the entire screen into 8x8 slots. We analyze each slot to see which symbol fits (yea this is the complicated part). Then we draw the symbol in that position. 

Yes there are a bunch of things I should do to make the output "look more like" the input, but I'll worry about them later. 