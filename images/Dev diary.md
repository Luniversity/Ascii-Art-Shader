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

8x32 sized cells. Tall cells look kinda weird. Hopefully it pays off to have flexible cells sizes. 

I now have a good foundation to starting figuring out what ascii symbol to put on the screen. I need to turn the rgb colours into luminance, convert that into a symbol using some index.

At this point I only care about luminance
![alt text](image-4.png)

Luminance is continuous and the ascii symbols are very much descrete. So we will need to do some quantization. 

I don't have the symbols yet so we will just quantize the colours. I basically made a resolution and colour downscaler.

![alt text](image-5.png)

8 colours only (imagine this is 8 different symbols)

With 8 colurs I chose 8 symbols that are kind of spread out evenly when it comes to density

![alt text](glyph_candidates_preview.png)

(The first one is blank since its the spacebar)

And now if we render each symbol at its correspoding place we get this:

![alt text](image-6.png)

Ascii art version 0 has been achieved.

But this setup uses 8x16 cells and is not very "pixel-like". I think it would be better if we actually used square fonts. This is what it looks like if i just squashed the current font down to a square:

![alt text](image-7.png)

The structure here looks much better, its just that the symbols looks a bit wacky. 

I then replaced the font with an actual square one. Now we can render cells at 8x8. Its tiny though so squint :)
![alt text](<1x0 8x8 3.png>)
![alt text](image-8.png)

Now the structure is even and the font looks right. 

Next I want to go back and improve the cell sampling. For each cell, I currently just look at the center of the cell and use that for calculating luminance. A better way to do this is to actually downscale the image by 8 so that we get a blurred/lower resolution version of the image. 

![alt text](image-10.png)

Looks a bit more cleaner. I also increased the intensity of the light so we get a better range of luminance.

![alt text](image-11.png)

### Day 2 

A good thing to add early on is debugging views:

Cell colour: what the image looks like after downscaling
![alt text](image-12.png)

Luminance: what the image looks like after converting rgb to luminance
![alt text](image-13.png)

GlyphIndex: what the image looks like after quantizing but before rendering any glyphs
![alt text](image-14.png)

