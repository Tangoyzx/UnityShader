# UnityShader
Some UnityShader



## 平面阴影(PlanarShadow)

王者和功夫熊猫使用的阴影方法，核心原理是把模型每个顶点投影到某个平面上，
优点是性能比较好，不需要渲染shadowmap和目标物体对shadowmap的采样
缺点是只能在平面显示，凹凸或者墙壁楼梯这种会穿帮，可以通过控制渲染顺序来减轻穿帮的影响。

这个版本实现的是全黑的阴影，假如需要半透明的阴影可以加上stencil辅助避免透明穿插问题。

本版本实现的是点光源的版本，影子有近小远大的效果，正常的应该是平行光。

![](https://github.com/Tangoyzx/UnityShader/blob/master/Assets/Gifs/PlanarShadow.gif)


## 扫描效果（SobelEdge）

基于图像处理Sobel算子的后处理描边效果，大概想做出一种扫描东西的感觉。

![](https://github.com/Tangoyzx/UnityShader/blob/master/Assets/Gifs/SobelEdge.gif)

## 透光效果（Transparency）

一种透光效果的近似做法，通过法线和部分trick算出后方折射光线方向，
然后根据LightAtten算出透光的强度，
然后与原物体正常光照的颜色合在一起。

![](https://github.com/Tangoyzx/UnityShader/blob/master/Assets/Gifs/Transparency.gif)