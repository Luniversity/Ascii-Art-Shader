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

A good thing to add early on is debugging views:

Cell colour: what the image looks like after downscaling
![alt text](image-12.png)

Luminance: what the image looks like after converting rgb to luminance
![alt text](image-13.png)

GlyphIndex: what the image looks like after quantizing but before rendering any glyphs
![alt text](image-14.png)

Looking at a bunch of pure white and pure black pixels does hurt your eyes. One easy fix for this is to just make the two colours we have, blakc and white, into something less black and less white. So I added a colour palette view mode to decrease the contrast a bit.

![alt text](image-15.png)

I could stare at this for at least 5 min

![alt text](image-16.png)

I asked codex to generate colour palettes and I can already envision a website that looks like this

### Day 2 - Edge detection

What we have now is basically a way to represent different luminance levels using ascii symbols. That is technically what the goal is. But ascii art is not about representing an image in this kind of accurate way. It mostly uses defined edges, to create something a bit more stylized. 

Ascii Art is more this:
![alt text](image-17.png)

Than this:
![alt text](image-18.png)

So we need to a way to render out clear edges so that shapes becomes more defined. More formally we need to find a strong, coherent image contours at full resolution an reduce them into one meaningful directional symbol per cell.

The symbols we are going to use are: | — / \ 

A cell below the edge threshold remains blank in the edge image. A qualifying cell receives the glyph that best follows the detected line. Then we can combine the edge-only image with the luminance based image into a composite. 

There is a lot of things to consider here, and many potential ways of doing it.
We need to preserve thin edges, so we have to do the edge detection before any downsampling (otherwise the edges will be blurred away). The edge detection needs to output both the edge strength and it's direction, so that we can put the corresponding symbol on it. A sobel filter is ideal.

We need to properly differenciate big and small gradients. A texture might have a lot of edges, but we would be wasting our time trying to add edges to it. So we need a way to pre-process the image so that only important edges are selected. 

Since we are creating 8x8 cells, we might have multiple contradicting edges inside a cell. So we need a way of measuing how consistently the pixels agree on one orientation. One cell can only have one edge direction.

Lastly we need not forget that we are aiming for real time processing.

### Day 3 - Edge Detection for real now

The sobel filter would need a full resolution version of our greyscale (luminance) image. The edge detection "materials" would go on a seperate branch. Before downscaling, we grab a full resolution linear luminance texture for later. 

Full resolution luminance image:
![alt text](image-19.png)

Next we will actuall perform the sobel filter. 
Here are the debug views to visualize the "edges" (gradients).

Sobel Magnitude: bright areas are higher magnitude gradients
![alt text](image-20.png)

Sobel Direction: different directions of the output vectors are coloured differently
![alt text](image-21.png)
The filter differenciates whether the gradient is going up or down, left or right. While we only care about whether the "edge" is vertical, horizontal or diagonal.
A gradient poiting left <- or right -> both correspond to a vertical line, while a gradient pointing up or down both correspond to a horizontal line. 

Looking at the result of the sobel filter makes me believe that we are close to getting a finalized edge detection algorithm. But given that the test environment is just some default unity 3d objects, it is probably not a suitable environment anymore. We need more variation, detials, and overall complexity. 

Now I could import something fancy or make a more complex scene, but it would be just easier to just work on a photograph instead. So I'll just plaster one on. 

Here is the sobel direction view for an actual photograph with details:
![alt text](image-22.png)
So clearly there is a lot "not edges" that is lit up here. The filter does not differenciate actual contours with noise of high frequency texture. If you look at the floor at the bottom, we are detecting a lot of edges, while in reality it is just a textured floor
![alt text](image-23.png)

However there are good news. The colouring (direction or gradients) is quite on point. Looking at the cityscape, I can tell that the filter correctly identified the contours of the buildings (even though it might get drowned out by the downscaling later)

So what we need to do is some pre-processing to help the sobel filter a bit. We really just need a way to reduce high frequency patterns while keeping the larger boundaries. 

The simplest way of doing that is by blurring. Blurring might get rid of details (we want that but it is a scary thought), but remember that we are going to downsample anyway, so details will be gone no matter what. 

Here is what the before and after looks like with and without a gaussian blur.
Before:
![alt text](image-24.png)
After:
![alt text](image-25.png)

Yea no, blurring like this kind of just emphasizes lower frequency details, and makes the contours thicker. It also does not solve the weird textures on the asphalt.
If we only add a light blur, we get unwanted texture edges. If we make the blur strong, the contours start disappearing. 

What we really need is more of a bandpass filter that preserves details at a scale where we actually care. We dont need to consider every tiny edge, we only care when they are large enough to become represented by the ascii cells. If we use a difference of gaussians (small blur - large blur) we can preserve strucures around the scale we want, while suppresing both tiny textures and larger gradients. Then we can give the output to sobel to find the edges. 

[TODO: explain how we went from adding DoG to finally getting clean enough edges to move on]

The difference of gaussians (DoG from now on) idea was useful, but it took a lot of testing to understand what it was actually useful for. 

So basically we blur the luminance image twice. Once with a smaller blur and once with a larger blur. Then we subtract them to get the DoG output. The two blur inputs look nearly identical on their own. This is fine since the DoG works by amplifying their small differences, not by comparing an obviously sharp image against an obviously blurry one. The goal is to make structures around a useful scale stand out, while reducing tiny texture and very broad lighting changes.

At first, just feeding this result into Sobel did not give us the clean contours we wanted. The output still behaved too much like a normal edge detector. Lots of thin lines, fragmented texture, and not enough clear shape. 

![alt text](image-26.png)
(I swapped the test image to an image of a church since the cityscape image was way too busy)
You can see the contour lines of the church, but the edges are not clear enough to just hand it over to sobel yet. What I decided to do is basically do half of the edge detection using DoG and half using sobel. 

The DoG result is still a greyscale image containing continuous values, but we want to simplify it into clear regions before applying Sobel. 

![alt text](image-27.png)

The small blur preserves more local detail, while the large blur spreads that information over a wider area. In parts of the image that change very slowly, the two blurred values are almost equal and cancel each other out. Around boundaries, however, they differ.

This creates a positive response on one side of a boundary and a negative response on the other. That is why an edge often appears as a pair of neighbouring red and blue lines. You can see it in the SignedDoG view:

![alt text](image-30.png)

- Red means smallBlur - largeBlur is positive.
- Blue means it is negative.
- Dark means the two blurs are almost equal.

The brighter the colour the bigger the difference is.

In the church photograph, the contours of the building are surrounded by red and blue lines. This tells us that the two blurs disagree around those boundaries, so the DoG has successfully detected something noteworthy. Most slowly changing areas are dark because the two blurs contain almost the same value there.

The Signed DoG view is useful for understanding the filter, but it is not yet the image we give to Sobel. Here is where `tau` comes into play. 

`response = smallBlur - tau * largeBlur`

`response >= threshold -> white`

`response < threshold -> black`

The traditional Difference of Gaussians uses tau = 1.

The Tau Adjusted DoG Response debug view visualizes this comparison with the threshold. 

`Red pixels = above threshold`

`Blue pixels = below threshold`

Dark pixels are close to the threshold.
With the defaul tau = 1 with threshold = 0.005:

![alt text](image-31.png)

Only the strongest positive parts of the Signed DoG passed the threshold. You can see thin (sometimes broken) lines of red around the church. Most pixels are blue.

Lowering the threshold accepts more pixels. At tau = 1, lowering it all the way to zero places the cutoff directly between the positive and negative Signed DoG responses. However, changing the threshold alone did not give us enough control over how the regions expanded and connected.

![alt text](image-32.png)
tau = 1, threshold = 0.001

The more useful change was lowering tau to 0.96.

We can rewrite the response like this:

`smallBlur - tau * largeBlur`

`= (smallBlur - largeBlur) + (1 - tau) * largeBlur`

At tau = 0.96, this becomes:

`response = SignedDoG + 0.04 * largeBlur`

So we still have the normal signed difference between the blurs, but we also add a small amount of the large blurred luminance.

This gives brighter regions a larger positive boost than darker regions. If the large blur at a pixel is bright, 4% of it may be enough to move that pixel above the threshold. If it is dark, the added amount will be much smaller.

In the church photograph, the sky is much brighter than the building. Lowering tau pushes most of the sky above the threshold, turning it red in the Tau Adjusted DoG Response view. The darker church receives a smaller boost and mostly remains below the threshold, appearing blue.

![alt text](image-33.png)

This is a much cleaner division. One larger region for the sky and another for the church. 

![alt text](image-34.png)

And now that we convert the result into a binary image, the sky becomes white and church becomes black. There are still white spots inside the church. These artifacts might become an issue depending on how large they are. The small ones however will probably get rejected if we are smart in the way we determine which cells becomes an edge. 

The 0.96 value for tau was not just picked because it cleanly worked on this image, its a good sweetspot for the range of test photos I used. 

Now that we have a simplified binary image, we can apply Sobel to find the boundaries between its black and white regions.

The sobel like before detects the boundaries between the black and white regions. This is a much more useful job for it. Rather than asking Sobel to decide which tiny detail is important, we first simplify the image into larger regions and let Sobel find the contours between them.

![alt text](image-36.png)
This is the output of the sobel filter. Since the image is just black and white, almost all of the output is of very high gradient magnitude. This view shows the direction of gradient instead, quantized to the 4 directional symbols we have. You can see that the results is pretty good when it comes to the relevant contours. The artifacts are still an issue, but I hope that they get reduced once we downscale. 

### Day 4 - Rendering the edges

Now that we know where the edges are we have to determine which cell deserve to become an edge symbol, and which should not. 
Here is the church image's cells. The more edge pixel the cell has, the brighter the cells is.
![alt text](image-37.png)

We need to factor in:
- How many potential edge pixels we have in our cell.

- The total sobel strength 

- The dominant direction of the edge

- The direction coherence (what if we have disagreeing edges wanting seperate things?)

`coherence = length(axialSum) / totalStrength;`

`orientation = 0.5 * atan2(axialSum.y, axialSum.x);`

- We also need to treat opposite gradients as the "same".

- We also treat opposite directions as the same line direction. A dark-to-light vertical edge and a light-to-dark vertical edge should both produce |, not two different answers.

- Lastly, since sobel gives us gradient direction, we need to convert it to edge direction. A vertical line = horizontal gradient.

The solution ended up being simpler than I expected. Each accepted edge pixel just votes for the kind of line it belongs to. Each cell ends up with four vote counts: one for each possible edge glyph. This gives us a simple directional histogram for the cell.

A cell becomes an edge candidate when:

- enough edge pixels voted for its strongest direction;

- that direction makes up a large enough share of all votes in the cell;

- the strongest direction has strictly more votes than the second strongest.

The result of the cell direction election:
![alt text](image-38.png)

The final selected cells after considering edge dominance
![alt text](image-39.png)

Then we just have to render out the correct symbol for each cell. For every pixel on the screen, the shader checks which cell its on, check's its directional candidates and votes, then samples the correspoding glyph from the texture. If there is no edge, we skip and just output the background image. Now we can see only the edge ascii before we combine it with the normal ascii image.

![alt text](image-40.png)
(The artifacts does not look too bad now that its rendered out)

Lastly we will just need to combine the two ascii images. I kept it simple: if the there is an edge in the cell, we prioritize the edge over the luminance glyph. Otherwise we render the luminance glyph. 

Note that the two systems work at different resolutions. The luminance is downsampled per cell, whil the edges are detected at full resolution and is downsampled towards the end.

Here is the combined result:
![alt text](image-41.png)

Hmm we could use more glyphs to colour for this image. 

Here are the results from all other test images:

![alt text](image-42.png)
![alt text](image-43.png)
![alt text](image-44.png)