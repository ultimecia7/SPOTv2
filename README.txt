Structure Preserving Object Tracking (SPOT v1.0)

This code accompanies the paper:
  Structure Preserving Object Tracking
  Lu Zhang and Laurens van der Maaten
  IEEE Conference on Computer Vision and Pattern Recognition (CVPR), 2013.

Contact: Lu Zhang and Laurens van der Maaten                                 
         {lu.zhang, l.j.p.vandermaaten}@tudelft.nl


------------
License
------------

  THIS SOFTWARE IS PROVIDED BY LU ZHANG AND AURENS VAN DER MAATEN ''AS IS'' AND ANY EXPRESS
  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO 
  EVENT SHALL LU ZHANG AND LAURENS VAN DER MAATEN BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
  BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING 
  IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY 
  OF SUCH DAMAGE.


------------
Citations
------------

In case you use SPOT code in your work, please cite the following paper:

@conference{luzhang,
author = {Lu Zhang and Laurens van der Maaten},
title = {Structure Preserving Object Tracking},
booktitle = {IEEE Conference on Computer Vision and Pattern Recognition (CVPR)},
year = {2013},
url = {http://homepage.tudelft.nl/19j49/Publications_files/CVPR2013.pdf}
}


------------
Requirements
------------

This code has been developed and tested with Windows 7, Matlab R2012b (32-bit and 64-bit).

This is the first version of our code online. The tracking scale is fixed to one scale. One test video (red flowers) and its annotations (every 5 frames) are provided with the code. The other movies we used in our experiments are available in separate files from the SPOT website. We are still working on making a more efficient version of our code publicly available.

-----
Usage
-----

>> demo

The demo code can straightforwardly be adapted to run on other movies. Make sure that each annotation file contains a 1x4 vector, named location, that contains the bounding box location of the object of interest. The location-vector takes the form [y x w h], indicating the top-left corner and the width and height of the bounding box.
