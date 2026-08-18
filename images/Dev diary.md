# Ascii Art Shader

### Day 0 - So how do we do this

Turning an image into ASCII sounds simple at first. Lets say each symbol is 8x8 pixels large. We divide up the entire screen into 8x8 slots. We analyze each slot to see which symbol fits (yea this is the complicated part). Then we draw the symbol in that position. 

Yes there are a bunch of things I should do to make the output "look more like" the input, but I'll worry about them later. 

Here is the first test scene I made. It rotates, thats it

![alt text](<Screenshot 2026-08-10 235510-2.png>)

## Day 1 - Make it exist first

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

## Day 2 - Edge detection

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

## Day 3 - Edge Detection for real now

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

## Day 4 - Rendering the edges

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

## Day 5 - Performance and Optimization

So far the only performance check's I've done is playing the animations in the 3d test environment. All I know is that the performance is "smooth", with no real knowledge on how much resources the calculatios are acctually taking up. 

So lets fix that shall we. 

The shader is first and foremost post-processing, so the game image is already rendered before we start processing it. So all of our work should be added on top of the rendering of the game iteself. 

A lot of the computational work is dependent on the amount of pixels the screen has. Because we need a lot of intermediate steps, we have to read "the screen" many times. We also have to write a full-resolution texture many times, one screen write. 

The reality is a bit more complex than this but it gives me a good understanding of the scale.

Ok so lets go over some important processing steps (not choronological order):

- Convert camera image from colour to luminance

This is relatively simple, we read the screen once, combine the rgb values in a specific way, and then screen write to output the luminance texture.

- Render the final glyph image

This is also relatively simple. We have the tiny glyph textures ready, so the gpu can probably keep most of them close in its cache. Sampling the glyph themselves does not require much complicated math.

- Gaussian blur

The specific gaussian blur I used has two passes: one horizontal and one vertical. Each uses a 5 pixel kernel. So thats equivalent to around 10 screen read in total. We do run two gaussian blurs for the DoG, but since they have the same radius but different weights, we only need to run the blur passes once, and just store the results in two different texture channels. 

The gaussian weights themselves are also a bit complex, since exponentials is more expensive than basic arithmatic. Currently we calculate them every time we need to find the weights, which might be expensive.

- Sobel filter

The kernel for the sobel filter has 8 pixels/values, so thats 8x screen reads, and 1 output write.

- Sobel filter output

This is the most complex texture we handle. The filter outputs a bunch of information, we store it using an RGBA16F format, so 16 bit floats in 4 channels. 

R = horizontal gradient, Gx
G = vertical gradient, Gy
B = accepted-edge flag
A = unused

This is so that the aggregation pass can read them and make a decision on which edge glyph to use. But we are actually allocating more storage space than we need. The accepted-edge flag is derived like this:

`accepted = length(gradient) > epsilon ? 1.0 : 0.0;`

This is a bit extra information since we can derive the same boolean later using informaiton we already have. The alpha channel is already unused, so we really only need 2 channels to convey all the information we need. (less memory use)

### Benchmark results

I created a benchmark that compares three rendeing modes.

1. Basline, no ascii
2. Luminance-only Ascii
3. Edge-aware Ascii

Here are the results (GPU):

- Baseline: 0.366 ms

- Luminance-only: 0.458 ms (+0.092 ms compared to baseline)

- Edge-aware: 0.566 ms (+0.108 ms compared to luminance only)

So the complete effect added a total of 0.201 ms. CPU frame time difference was only 0.073 ms. These are very low numbers, but I am on a 9070 XT so these number will increase for an average computer. 

Total frame time difference for the effect should be around 1.2% of a 60FPS target or 2.4% of a 120FPS target.

I also tried to render at 4k, where the complete effect cost (gpu + cpu) increased from 0.22 ms to 1.49 ms in editor. 4k means 4 times the amount of pixels, but the shader took 6.8 times longer to run, so some aspects are scaling worse than expected. 

Overall the shader is quite cheap at 1080p, so there is no rush to optimize. I don't have a specific target for optimization, the initial plan was "real time" so i guess that means 60FPS. 

## Day 6 - Dynamic Luminance Quantization

### The idea 
One issue I noticed with the portrait test photo was that a lot of areas of the image consisted of blank glyphs, the cells were determined to be too dark so nothing was rendered. You can see that the background, some of the foreground, and the subjects' hair is blank. Wheras in the real photo, those areas range from truly black to important subject areas that happens to be darker. 

![alt text](image-43.png)
![alt text](image-45.png)

So what is going on here is that the dynamic range of the image is narrower than the entire luminance band we have glyphs for. This photo for instance only has luminance ranges that render out 7 out of 10 glyphs. So the ?, @ and square is never even used. This is not the fault of the image, it was taken at night and just happened to not have strong highlights and strong shadows at the same time. 

So what can we do about this? Ideally we would want to use as many glyphs as possible to represent the image. Maybe we could create a way to force all 10 glyphs to be used at the quantization stage. Lets say luminance is represented continuously from a scale from 0-1. The way we currently quantize luminance is to count the number of glyphs we have (10) and evenly distribute them across the luminance range, so glyph1 would be 0-0.1, glyph2 would be 0.1-0.2 etc. 

This would make sense if we were doing posterization. If we were quantizing colours stylistically, we would want a colour to still be somewhat similar after quantizing. But since we are dealing with ascii glyphs (that are the same colour and luminance to each other) we care less about the absolute luminance and more about the relative luminance. 

So if an image only ranges from 0-0.5 in terms of luminance, maybe we could fit all 10 glyphs inside that range instead. That would mean that we get more available glyphs to render the photo, which would render gradients of luminance better. No more crushed blacks or whites. Also when determining "dynamic range" what we really care about is what the brightest and darkest cell is, not pixel. A single bright pixel existing does not mean that we will need to render out a bright glyph. So what this tell me is that we need to do this calculation on the downscaled luminance image. 

I can also forsee that there could be a general mismatch of luminance across different images. An equally bright area in two photos might be represented by two different glyphs depending on the dynamic range of the image. Is this fine? Artistically I am leaning towards yes since it makes each indivdual image look better, at the cost of consistency. 

We could take our quantization logic even further. Each glyph has a statistical "brightness", a measure of how many lit pixels compared unlit pixels. Our current way of quantizing glyphs assumes that each glyph is evenly distributed in terms of brightness, when in reality the number of lit pixels in each glyph does not increase steadily. (not sure how much of an impact this will have though)

### Remapping Black and White points

The safest first thing to do is a manual check to see if narrowing the luminance band will produce a favourable result. No algorithm that determines exactly where the black and white point is yet.

So basically I added a way to remap each cell's luminance value (without touching the full resolution texture).

Here is the church test image again. You can see that remapping the luminance from 0.0 - 1.0 to 0.0 - 0.5. Changes the output a lot. What the remapping does is essentially saying that any pixels that has luminance above 0.5 is considered 0.5, see the red pixels in the luminance range clipping image. So some pixels is supposed to be brighter but we are clipping the luminance, while the vast majority of pixels are not clipped. Now we have every pixel ranging between 0.0 - 0.5 in luminance, and quantize (evenly still) between that range. 

<p align="center">
  <img src="image-50.png" width="90%" alt="Luminance range clipping mask">
  <br>
  <em>Luminance range clipping: green cells are inside the selected range, while red cells exceed the 0.5 white point.</em>
</p>

Imagine the histogram of the image pre and post remapping. Before remapping, the pixels had a certain distribution located mostly under 0.5, what we did is that we clipped the pixels above 0.5 and stretched the histogram so that it occupied then entire 0-1 range. 

| Original cell luminance | Remapped cell luminance |
|:---:|:---:|
| <img src="image-46.png" width="100%" alt="Original church cell luminance"> | <img src="image-48.png" width="100%" alt="Remapped church cell luminance"> |
| Original 0–1 mapping | The 0–0.5 range stretched across 0–1 |

Now, pixels that were close to 0.5 in luminance gets assigned the brightest glyphs, instead of a medium bright glyph. You can see that the background clouds have some brighter spots now. 

Areas that was previously towards the darker side pre-remapping gets brigher. You can see that the church itself was mostly made of blank glyphs but now has some texture to it.

| Without luminance remapping | With luminance remapping |
|:---:|:---:|
| <img src="image-47.png" width="100%" alt="Church ASCII without remapping"> | <img src="image-49.png" width="100%" alt="Church ASCII with remapping"> |
| Much of the church selects blank or sparse glyphs | More of the glyph ramp represents the church |

Note: the 0.5 white point I chose was arbitrary, we should ideally find a good way of determining a white and black point automatically. 

### Automatically determining black and white points

An important distintinction to make is between the literal brightest/darkest cells in the image and the darkest/brightest cells that are useful for describing the image.

We could just find the literal min and max luminance of the image. So if an image only ranges between 0.05-0.65 we remap that to 0-1. But that would leave us vulnerable to outlying cells. Like what if a bright light sources at luminance = 0.95 exists? that would limit our remapping even if the rest of the image if fairly dark. 

A better way would be to look at percentiles. But that requires sorting and I kinda just want to see how well the dumb version works first. 

The obvious way of finding the min and max is to let the cpu do the work. It would involve sending the cell texture to the cpu, then asking it to run something akin to:

`minimum = Mathf.Min(minimum, luminance);`

`maximum = Mathf.Max(maximum, luminance);`

But that would involve us transferring the result of previous processing to the cpu and making sure they syncronize. So we should keep the work on the GPU. But on the GPU we can't just ask it to loop through the image and keep track of min and max like we do on the CPU, we have to tell it to work in parallel. 

The plan is to then use a reduction chain. The grid of cells we have is 240x135 (1080p). We send out a GPU thread for each 2x2 group of cells and it does its own min or max calculation, and outputs its resulting pixel. A lot of these threads run in parallel. From this we get an downscaled texture with all the "winners", we then just keep running this until we are left with a single cell, which becomes our brightes or darkest cell. This is a very dumb but fast way of finding the min or max, we only care about the value of the cell, not the position, so its okay. 

I ran the automatic black and white bonds on every test scenario I had, and the results were interesting. All of the images were bound around 0-0.5, coincidentally what I tested with, while the 3d environment's range did not deviate much from 0-1. So if the test images I have is anything to go with, then we are effectively doubling the dynamic range. A dark area with a luminance of 0.1 effectively becomes 0.2 after remapping. 

(Since the automatic bounds detection gives the same bounds as my testing, see the previous church image for reference)

### Preventing excess quantization

Lets say an image is just one shade of grey. I it would then be dumb to start analyzing dynamic range bounds and remap the luminance. We would be dividing a tiny luminance range to fit 10 glyphs, while in reality the image is just "one colour". So we need a minimum range where we actually decide to remap stuff. 

A convenient minimum we could use is `minimum_range = 1 / glyph_count`. Which for me is 0.1. So if an image only ranges enough to need one (or less) glyphs to represent everything, we just skip remapping and keep the 0.1 range. That would result in the image becoming only one glyph. 

The issue with that is if an animation crosses the boundary and goes from 0.099 to 0.101, we would get a weird jump. So we will need to ease it in a bit:

    range <= one glyph step:
        use fixed mapping

    range >= two glyph steps:
        use full automatic remapping

    between them:
        gradually blend from fixed to automatic

### Problems when introducing motion

The automatic bounds worked well for static images, but video games introduce another requirement: the result must remain stable between frames.

The shader currently calculates new black and white points independently for every frame. This means that a bright or dark object entering the camera can change the luminance mapping for the entire image.

For example, imagine that a cell has a luminance of 0.25:

    Frame A bounds: 0.0–0.5
    Remapped luminance: 0.5

    Frame B bounds: 0.0–1.0
    Remapped luminance: 0.25

The cell itself did not change, but a bright object entered somewhere else and increased the detected white point. The unchanged cell can suddenly move several positions down the glyph ramp.

Because glyph selection is quantized, this does not appear as a subtle brightness adjustment. Many cells can suddenly switch symbols at the same time. During testing, this appeared as flickering and unintended changes across otherwise stable parts of the image. The luminance bounds are global values, so a local change can affect every cell on screen.

So how do we fix this?

One option would be to smooth the detected bounds over time. Instead of immediately using the newest bounds, we would gradually move toward them.

This would reduce sudden jumps, but the shader would temporarily use information from older frames. Highlights could remain clipped while the white point catches up, and camera cuts could briefly use the bounds from the previous shot. This improves stability at the cost of responsiveness and accuracy.

Another option would be percentile bounds. Instead of using the literal brightest and darkest cells, we could ignore a small percentage of extreme cells.

The ignored cells would still become the brightest or darkest glyphs, but they would no longer control the mapping of the rest of the image. This would probably reduce the flickering caused by small highlights. However, we would have to decide how many cells are allowed to be ignored. A genuinely important highlight could be treated as an outlier, and different scenes might prefer different percentiles.

We also considered deadbands and requiring an extreme value to remain for several frames before accepting it. These approaches can reject small or temporary changes, but they either delay real changes or still allow larger jumps.

Every solution introduces some form of lag, ignored information, or arbitrary threshold.

### Final Decision :(
    
For animated content, using every glyph is less important than preserving stable and accurate motion.

Because of this, the default real-time mode will keep the original fixed 0–1 luminance mapping. A cell with the same luminance will continue selecting the same glyph regardless of what enters another part of the screen.

Automatic min/max remapping will remain available for static images. The photographs consistently benefited from the expanded range, and static images do not suffer from temporal flickering.

The public shader therefore has two modes:

Stable: fixed luminance mapping intended for games and animation

Adaptive Static Images: automatic min/max remapping intended for photographs

Stable is the default. The shader does not try to detect whether the source is moving; the mode represents the intended use.

This changes the goal slightly. We are no longer trying to force every frame to use the complete glyph atlas. We use more of the ramp when it can be done safely, but temporal stability takes priority for real-time rendering.

A future alternative could be an atlas containing more glyph densities. A larger fixed ramp would provide more tonal variety within a narrow luminance range without changing the mapping between frames.

## Day 7 - ReShade porting

Ok I have never touched reshade before, I have only downloaded it to use a preset someone made. Lets see how this goes. 

This is as far as my ReShade experience gets me for free:

![reshade overlay on build](image-51.png)

ReShade effects are written in .fx files using a language similar to HLSL. Instead of using Unity C# and Render Graph to schedule the work, the effect file declares its own textures, shader passes and technique. Which is kind of nice, working on the renderer feature was a pain. 

Before testing real games, I used a Windows build of the Unity test environment as a controlled ReShade host. The actual port of the algorithm was built back up in stages:

1. cell sampling and luminance glyphs

2. glyph atlas rendering

3. color modes

4. full-resolution luminance and Sobel

5. Gaussian and Difference-of-Gaussians preprocessing

5. directional edge classification

7. edge glyph rendering and the final composite

There was one issue when I tried to port over the algorithm. The ReShade result had the correct structure, but it consistently selected brighter and denser glyphs than Unity. The problem was not the cell grid, averaging or quantization. ReShade was reading the game’s final sRGB backbuffer, while the Unity implementation performed its calculations using linear color values.

sRGB values make most midtones numerically brighter. If those values are used directly for luminance calculations, cells move further up the glyph ramp.

The solution was to convert every source pixel from sRGB to linear before it contributes to the cell average. After adding this conversion, the ReShade and Unity glyph selections became basically identical. 

![alt text](image-55.png)

Even the "Made with unity" screen was made of Asciis now that the entire build was affected by the shader.

### Using the Shader in actual games (Expedition 33)

This is good time to show what the shader currently looks like in actual games

| Landscape: Ascii OFF | Landscape: Ascii ON |
|:---:|:---:|
| <img src="image-58.png" width="100%" alt="Church ASCII without remapping"> | <img src="image-57.png" width="100%" alt="Church ASCII with remapping"> |

| Portrait: Ascii OFF | Portrait: Ascii ON |
|:---:|:---:|
| <img src="image-60.png" width="100%" alt="Church ASCII without remapping"> | <img src="image-59.png" width="100%" alt="Church ASCII with remapping"> |

When it comes to luminance, you can see that the shader is quite good already. Any direct improvements that I can see would come from adding more glyphs. But this is totally usable. 

As for edges, real games introduce a much more complex (sometimes) image for us to analyze, which results in inconsistent edges in some more complex areas. A lot of the edge issues is inevitable when we lose details when downscaling, however there are some things we could do about it (i'll discuss this later).

Using this shader in an actual game introduces some more issues, such as flickering/a noisy output. I dealt with potential visual artifacts like this when doing dynamic luminance quantizing (it was the reason it was scrapped). However in here, flickering is substantial even when nothing is visually changing. 

The test images from e33 were captured using the in game photo mode, where all animations were paused, yet the ascii output was still noisy. This is more of a problem since nothing is happening inside the game, yet the shader percieves a lot of "movement". 

I'll compile all the issues and potential improvements here:

- Flickering/Noisy output, even when there is any animation. We should find a way to prevent this, or smooth the output to make it less harsh. We need also make sure that any measures we take against noise should not come at the expense of real animations.

- The cell tint colour mode might need an upgrade. Currently the colours are way too harsh, since they have full saturation and luminance. We need a nuanced upgrade that improves colour accuracy, and takes the luminance of the glyph colour and the luminance of the cell's colour into account. Currently we disregard luminance and saturation, and rely on the density of the glyph to fake luminance, that might not be enough now that we are working with a detailed game world. We can discuss what specifically to try later.

- Edge detection struggling in certain areas. We can't make edges perfect with limited detail, but we can now use the depth buffer to inform our choices for edges. Adding more ways of detecting edges (and maybe tuning down our current edge detection) might improve edge detection as a whole.

- A stylistic improvment would be to only draw edges within a certain distance of the camera. This way characters and detailed close up objects gets defined edges, while the background turns more smooth. 

- Another improvement is to control the opacity of the glyphs. We could fade out glyphs that were further away from the cameras. 

- I also have ideas on what other effects that might work well with this shader. But we can think about that later. 

More Images of Lune:
![alt text](image-61.png)
![alt text](image-62.png)

## Day 8 

### Temporal Stability

A lot of the noise probably comes from rendering techniques like TAA and upscaling. You cant avoid these things in modern games so we have to deal with it. These methods deliverately change or jitter pixels between frames, however the changes are so small that you normall cant see them. But our shader makes a lot of decision based on hard thresholds, so the jitter will sometimes cross the threshold between frames, creating noise.

A tiny luminance change can move a cell across the boundary between two glyphs. Edge detection is even more sensitive. A small change can alter the binary DoG result, which changes the directional votes inside a cell. That cell can then switch between being an edge and not being an edge, or switch between two edge directions.

The final candidate mask is binary, so a small change in a few source pixels can change an entire 8x8 cell. This made the edge noise look much stronger than the noise that caused it.

I really only noticed this now since I have been working on static images of very simple unity animations. So now that we can test in real games we finaly encounted this issue. 

I did not want to average multiple frames together.
That would basically entail the shader averaging multiple frames to gether to smooth the motion, that would reduce the noise but would also blur movement and make the shader just slower overall to react to stuyff. 

So instead I created a seperate requirements for edges depending on whether the previous frame was an edge or not. 

Creating a new edge has fairly strict requirements:

    Entry support: 8 pixels
    Entry dominance: 0.65

Once an edge exists, it is allowed to remain with slightly weaker evidence:

    Retention support: 6 pixels
    Retention dominance: 0.3

This creates a small safe region between appearing and disappearing. For example, an edge that fluctuates between seven and eight supporting pixels no longer repeatedly turns on and off. It must reach eight pixels to appear, but once it exists it can remain until its support falls below six.

The shader also remembers the previous edge direction. A new direction must beat the retained direction by three votes before the glyph is allowed to change. This prevents small variations in the directional histogram from repeatedly swapping between -, |, / and \

This is not enough for history to preserve an edge on its own. The current frame must still contain enough evidence supporting it. If the edge actually disappears, the stored edge is removed instead of leaving a trail.

### Cell tint improvements

Next I wanted to address the Cell tint colour mode. It was initially added for fun to make the glyphs have the colours of the objects behind it. The original Cell Tint mode only cared about the general colour of the cell. It divided the colour by its brightest RGB channel, which preserved its hue and saturation but always forced its HSV Value to 1.

This made sense since hue and saturation belonged to the tint of the glyph, while the luminance (value) belonged to the glyph density. We already represent darker and brigher areas with different glyphs, so making the glyph's colour brighter or darker felt redundant. 

However with the shader in action it often felt like the colours were too intense, especially in darker areas. The contrast between the fully bright glyphs and the blank glyphs was stark, making it hard on the eyes. 

To improve this, I added a Value Influence setting. It blends between the original full-Value colour and the actual Value of the source cell.

    0.0 = original full-Value tint
    1.0 = complete source-cell Value

Using the complete source Value was too strong because glyph density was already trying to represent the same luminance. Dark glyphs became difficult to see and too much colour detail disappeared.

Values around 0.6–0.7 produced the best artistic result, with 0.65 being a good general setting. It allows the source Value to affect the colour without completely replacing the work done by glyph density.

The two extremes show the tradeoff between colour visibility and softer contrast:

| Value Influence: 0.0 | Value Influence: 1.0 |
|:---:|:---:|
| <img src="image-63.png" width="100%" alt="Cell Tint with no source Value influence"> | <img src="image-64.png" width="100%" alt="Cell Tint using complete source Value"> |
| Every glyph uses full Value, preserving detail but producing harsh colours. | Dark glyphs blend into the background, but too much colour detail is lost. |

The chosen compromise keeps much of the softer contrast without losing as much detail:

| Value Influence: 0.65 |
|:---:|
| <img src="image-65.png" width="100%" alt="Cell Tint with the chosen 0.65 Value influence"> |
| Dark areas are calmer while foreground colours and important details remain readable. |

### Working with depth

Adding depth knowledge will probably improve most aspects of the shader. Here is the linearized and reversed depth buffer i get from reshade.

The brighter the pixels get, the farther away they are from the camera.
![alt text](image-68.png)
![alt text](image-67.png)

Since the depth buffer contains few tiny details and is not affected by lighting or textures, we can skip the DoG preprocessing step and directly run the sobel filter on the depth buffer. 

After running sobel we get this:

![alt text](image-69.png)

Brighter = More likely an edge
You can immediately see that the places we want to draw edges already is white. Howeverwe are getting a lot of artifacts.

1. It looks like it is snowing. The game renders particles that has depth. When they are placed against a background the sobel sees the difference and colours it white.

2. The background objects are also super white. This makes sense since they are equally defined and is against a far away background. However we should ideally care about depth-edges more when they are closer to the camera. 

3. We are getting the same noise we observed when first porting to ReShade, so we might need to run similar temporal stability measures as before.

### Prioritizing closer edges

The Sobel filter only tells us how large the difference in depth is. It does not understand whether an edge belongs to an important foreground object or an unimportant building in the distance. 

To fix this, I added a proximity weight. For every Sobel sample, the shader looks at the closest depth in the surrounding 3x3 area. Edges close to the camera keep their original strength, while edges gradually become weaker as they get farther from the camera. This means that nearby edges receive full strength. Their influence then gradually fades out as it gets further away. At a certain distance, they disappear completely.

Before:
![depth sobel magnitude](image-70.png)
After:
![weighted depth sobel magnitude](image-71.png)

After applying the proximity weight, the very strong edges around distant buildings were reduced. I then applied a relatively strict magnitude threshold. Real object silhouettes normally produced much stronger depth gradients than small particles and other artifacts, so this removed a large amount of the unwanted depth information.

![binary depth edge mask](image-72.png)

Using the same voting system as the other edge aggregation method, but with a slighlty tweaked settings, gives us the a rendered version of depth detected edges with asciis

But we still need to address temporal stability. Hair and other thin shapes were still noisy. They could create a valid edge in one frame and then lose most of their support in the next frame because of small changes in movement, TAA or the depth buffer.

I reused the temporal hysteresis system from the image edges, but with more forgiving retention settings:

    Entry support: 10 pixels
    Entry dominance: 0.5

    Retention support: 2 pixels
    Retention dominance: 0.1
    Direction switch margin: 3 pixels

The strict entry requirements prevent weak particle edges from appearing in the first place. Once an edge has proved that it is real, the forgiving retention requirements allow it to survive temporary drops in evidence. We can get away with this since the important contours we care about are less prone to the same kind of noise luminance based edge detection. 

![alt text](image-73.png)

### Combining image and depth edges

Now that we have edge information from two sources, I had to decide what to do when the two systems disagreed on whether there should be an edge or not (or which orientation the edge is in). Both systems are useful and good at different things. Image edges can see edges caused by colour and texture, while depth edges are much better at finding silhouettes of objects. 

The simplest way of doing this is to combine the final output/decision by each system, instead of merging them earlier. 

So if there is a valid depth edge -> Use its direction
Else -> Use the image-based edge information
If neither system detect an edge -> Use regular luminance glyph

This way the depth edges gets priority since they are more likely to be edges we perceive to be real.

Here is the final result:

![no edges](image-74.png)
![image edges](image-75.png)
![image and depth edges](image-76.png)