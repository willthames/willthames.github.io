---
title: Problems with graphviz font selection
date: 2014-03-20 13:14
layout: post
---
When tweeting about my recent [Ansible post](/2014/03/17/ansible-layered-configuration-for-aws.html)
I mentioned that graphviz selection problems were the cause of some delay. [@magneticnorth](https://twitter.com/magneticnorth)
responded that it was dismaying given the size of the underlying font handling libraries. So I thought I'd give a more detailed
breakdown.

First, let's give it some context.

The [inventory image](/images/inventory.png) was generated using graphviz's dot from 
a [dot source file](https://github.com/willthames/willthames.github.io/blob/master/dot/inventory.dot).

Font selection in dot labels can be done a number of ways, but the resolution of the fonts (i.e. 
what system fonts to use to render the fonts requested in the dotfile) is where things go wrong. 
Here's an example dot file:
{% highlight text %}
digraph dummy { 
  a -> b -> c -> d -> e -> f -> g -> h -> i;
  a [fontname="Times New Roman, Bold"]
  b [fontname="Times New Roman Bold"]
  c [fontname="Times, Bold"]
  d [fontname="Times Bold"]
  e [fontname="Times-Roman, Bold"]
  f [fontname="Times-Roman Bold"]
  g [fontname="Times-Roman-Bold"]
  h [fontname="Times-Bold"]
  i [fontname="Times-New-Roman-Bold"]
}
{% endhighlight %}

And the results of the dot conversion (on a Fedora 20 machine with fairly standard fonts - it didn't
go better on a different Fedora 20 machine with the MS core fonts installed):
{% highlight text %}
fontname: "Times New Roman, Bold" resolved to: (PangoCairoFcFont) "Liberation Serif, Bold" /usr/share/fonts/liberation/LiberationSerif-Bold.ttf
fontname: "Times New Roman Bold" resolved to: (PangoCairoFcFont) "DejaVu Sans, Bold" /usr/share/fonts/dejavu/DejaVuSans-Bold.ttf
fontname: "Times, Bold" resolved to: (PangoCairoFcFont) "Nimbus Roman No9 L, Medium" /usr/share/fonts/default/Type1/n021004l.pfb
fontname: "Times Bold" resolved to: (PangoCairoFcFont) "Nimbus Roman No9 L, Medium" /usr/share/fonts/default/Type1/n021004l.pfb
fontname: "Times-Roman, Bold" resolved to: (PangoCairoFcFont) "DejaVu Sans, Bold" /usr/share/fonts/dejavu/DejaVuSans-Bold.ttf
fontname: "Times-Roman Bold" resolved to: (PangoCairoFcFont) "DejaVu Sans, Bold" /usr/share/fonts/dejavu/DejaVuSans-Bold.ttf
fontname: "Times-Roman-Bold" resolved to: (PangoCairoFcFont) "DejaVu Sans, Book" /usr/share/fonts/dejavu/DejaVuSans.ttf
fontname: "Times-Bold" resolved to: (ps:pango  Nimbus Roman No9 L, ) (PangoCairoFcFont) "Nimbus Roman No9 L, Regular" /usr/share/fonts/default/Type1/n021003l.pfb
fontname: "Times-New-Roman-Bold" resolved to: (PangoCairoFcFont) "DejaVu Sans, Book" /usr/share/fonts/dejavu/DejaVuSans.ttf
{% endhighlight %}

There's very little consistency or reason to why certain fonts resolve to DejaVu Sans and others resolve to non Bold versions.
Only "Times New Roman, Bold" resolves to anything reasonable. And that was thanks to a handy hint in a 
[graphviz bug report](http://www.graphviz.org/bugs/b1304.html)!

To be clear, I know it's the underlying libraries that are most likely at fault rather than graphviz, but there is little
adequate documentation of how best to specify font selections (lots of FIXME notes in the [graphviz font FAQ](http://www.graphviz.org/doc/fontfaq.txt)). 
The FAQ did at least tell me how to know what fonts were being chosen, even if not why. 


