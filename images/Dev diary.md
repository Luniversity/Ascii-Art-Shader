# Ascii Art Shader

### Day 0 - So how do we do this

Turning an image into ASCII sounds simple at first. Lets say each symbol is 8x8 pixels large. We divide up the entire screen into 8x8 slots. We analyze each slot to see which symbol fits (yea this is the complicated part). Then we draw the symbol in that position. 

Yes there are a bunch of things I should do to make the output "look more like" the input, but I'll worry about them later. 

Here is the first test scene I made. It rotates, thats it

![alt text](<Screenshot 2026-08-10 235510-2.png>)

### Day 1 - Make it exist first

I'll start by making the smallest complete path from camera image -> shader -> back to the screen. So basically creating a shader that does nothing but pass the same information along.

![alt text](image.png)

Holy hell the shader exists and makes things more red

A frag shader normally treats every output pixel independently. But for my ascii rendering we need groups of pixels to form cells, that later turn into an ascii character. So we need: individual screen pixels -> groups of pixels into fixed cells. We can later then do math and analysis on each cell to determine a symbol.

I'm on a 4k screen so idk how small pixel counts will look on my screen physically. I might try to just work on 1080p idk. 

Next, I created the actual cells. All the cells are is just fixed sized squares.

![alt text](image-1.png)

The cell size here is 8px on a 1080p screen. That looks like a size to put symbols on. 16px is too big, and 4px kinda drowns out the cells. 

But this is just an arbitrary checkboard pattern. I need to actually make use of the screen pixels, and do stuff with it. The simplest thing I could do with the pixels is to just choose the center pixel (of the cell) and fill the cell with that colour.

![alt text](image-2.png)

Now it looks like a "poorly" downscaled image of the original scene. 

So far we are making every cell a square. But a lot of fonts are rectangular. So I should make sure to that cells could be sizes like 8x16 pixels and still work. 

![alt text](image-3.png)

Tall cells look kinda weird. Hopefully it pays off to have flexible cells sizes. 