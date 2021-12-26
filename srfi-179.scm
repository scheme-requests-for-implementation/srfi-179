(include "html-lib.scm")

(define (format-lambda-list lst #!optional id)
  (let ((name (car lst))
        (arguments (cdr lst)))
    (<p> (<b> "Procedure: ")
         (<code> (<a> id: (if id id name) name)
                 (map (lambda (arg)
                        (list " " (cond ((symbol? arg)
                                         (<var> arg))
                                        ((keyword? arg)
                                         arg)
                                        (else
                                         arg))))
                      arguments)))))

(define (format-global-variable name)
  (<p> (<b> "Variable: ")
       (<code> (<a> id: name name))))

(with-output-to-file
    "srfi-179.html"
  (lambda()
    (html-display
     (list
      (<unprotected> "<!DOCTYPE html>")
      (<html>
       lang: 'en
       (<head>
        (<meta> charset: "utf-8")
        (<title> "SRFI 179: Nonempty Intervals and Generalized Arrays (Updated)")
        (<link>
         rel: "icon"
         sizes: "192x192"
         type: "image/png"
         href: "/favicon.png"
         )
        (<link> href: "https://srfi.schemers.org/srfi.css"
                rel: "stylesheet"
                type: "text/css")
        (<meta> name: 'viewport
                content: "width=device-width, initial-scale=1")
        (<script> type: "text/x-mathjax-config" "
MathJax.Hub.Config({
  tex2jax: {inlineMath: [['$','$'], ['\\\\(','\\\\)']]}
});")
        (<script> crossorigin: "anonymous"
                  integrity:"sha384-Ra6zh6uYMmH5ydwCqqMoykyf1T/+ZcnOQfFPhDrp2kI4OIxadnhsvvA2vv9A7xYv"
                  src: "https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-AMS-MML_HTMLorMML")
        )
       (<body>
        (<h1> (<a> href: "https://srfi.schemers.org/" (<img> class: 'srfi-logo src: "https://srfi.schemers.org/srfi-logo.svg" alt: "SRFI logo")) "179: Nonempty Intervals and Generalized Arrays (Updated)")

        (<p> " by Bradley J. Lucier")

        (<h2> "Status")
        (<p> "This SRFI is currently in " (<em> "final") " status.  Here is "
             (<a> href: "https://srfi.schemers.org/srfi-process.html" "an explanation")
             " of each status that a SRFI can hold.  To provide input on this SRFI, please send email to "
             (<code> (<a> href: "mailto:srfi+minus+179+at+srfi+dotschemers+dot+org"
                          "srfi-179@" (<span> class: "antispam" "nospam") "srfi.schemers.org"))
             ".  To subscribe to the list, follow "
             (<a> href: "https://srfi.schemers.org/srfi-list-subscribe.html" "these instructions")
             ".  You can access previous messages via the mailing list "
             (<a> href: "https://srfi-email.schemers.org/srfi-179" "archive")".")
        
        
        (<ul> (<li> "Received: 2020-01-11")
              (<li> "Draft #1 published: 2020-01-11")
              (<li> "Draft #2 published: 2020-01-25")
              (<li> "Draft #3 published: 2020-02-04")
              (<li> "Draft #4 published: 2020-03-25")
              (<li> "Draft #5 published: 2020-04-30")
              (<li> "Draft #6 published: 2020-05-03")
              (<li> "Draft #7 published: 2020-05-08")
              (<li> "Draft #8 published: 2020-05-17")
              (<li> "Draft #9 published: 2020-05-31")
              (<li> "Draft #10 published: 2020-06-02")
              (<li> "Draft #11 published: 2020-06-28")
              (<li> "Finalized: 2020-06-30")
              (<li> "Revised to fix errata:"
                    (<ul> (<li> "2020-10-08 (Fix documentation for "(<code>'interval-subset?)".)")
                          (<li> "2021-02-24 (Correct the note comparing  "(<code>'array-curry)" and "(<code>'array-tile)".)")
                          (<li> "2021-05-02 (Correct documentation of "(<code>'interval-cartesian-product)"; document initial values for "(<code> "(specialized-array-default-safe?)")" and "(<code> "(specialized-array-default-mutable?)")".")))
              (<li> id: 'pfn1 "Post-finalization note added on 2020-12-10: The document
was updated to improve the examples and to explain the use of "(<code>'array-copy)" to
improve efficiency in some situations.")
              (<li> id: 'pfn2 "Post-finalization note added on 2021-01-17: The document
was updated to explain that \"lexicographical order\" is the same as \"row-major order\"."))

        (<h2> "Abstract")
        (<p>
         "This SRFI specifies an array mechanism for Scheme. Arrays as defined here are quite general; at their most basic, an array is simply a "
         "mapping, or function, from multi-indices of exact integers $i_0,\\ldots,i_{d-1}$ to Scheme values.  The set of multi-indices "
         "$i_0,\\ldots,i_{d-1}$ that are valid for a given array form the "(<i>'domain)" of the array.  In this SRFI, each array's domain consists "
         " of the cross product of nonempty intervals of exact integers $[l_0,u_0)\\times[l_1,u_1)\\times\\cdots\\times[l_{d-1},u_{d-1})$ of $\\mathbb Z^d$, $d$-tuples of "
         "integers.  Thus, we introduce a data type "
         "called $d$-"(<i> 'intervals)", or more briefly "(<i>'intervals)", that encapsulates this notion. (We borrow this terminology from, e.g., "
         " Elias Zakon's "(<a> href: "http://www.trillia.com/zakon1.html" "Basic Concepts of Mathematics")".) "
         "Specialized variants of arrays are specified to provide portable programs with efficient representations for common use cases.")
        (<h2> "Rationale")
        (<p> "This SRFI was motivated by a number of somewhat independent notions, which we outline here and which are explained below.")
        (<ul>
         (<li> "Provide a "(<b> "general API")" (Application Program Interface) that specifies the minimal required properties of any given array, without requiring any specific implementation strategy from the programmer for that array.")
         (<li> "Provide a "(<b> "single, efficient implementation for dense arrays")" (which we call "(<i>"specialized arrays")").")
         (<li> "Provide "(<b> "useful array transformations")" by exploiting the algebraic structure of affine one-to-one mappings on multi-indices.")
         (<li> "Separate "(<b>"the routines that specify the work to be done")" ("(<code>'array-map)", "(<code>'array-outer-product)", etc.) from "(<b>"the routines that actually do the work")" ("(<code>'array-copy)", "(<code>'array-assign!)", "(<code>'array-fold)", etc.). This approach "(<b> "avoids temporary intermediate arrays")" in computations.")
         (<li> "Encourage " (<b> "bulk processing of arrays")" rather than word-by-word operations.")
         )
         (<p> "This SRFI differs from the finalized " (<a> href: "https://srfi.schemers.org/srfi-122/" "SRFI 122")" in the following ways:")
        (<ul>
         (<li> "The procedures "
               (<code>'specialized-array-default-mutable?)", "
               (<code>'interval-for-each)", "
               (<code>'interval-cartesian-product)", "
               (<code>'interval-rotate)" and "
               (<code>'array-elements-in-order?)", "
               (<code>'array-outer-product)", "
               (<code>'array-tile)", "
               (<code>'array-rotate)", "
               (<code>'array-reduce)", " 
               (<code>'array-assign!)", "
               (<code>'array-ref)", "
               (<code>'array-set!)", and "
               (<code>'specialized-array-reshape)
               " have been added together with some examples.")
         (<li> "Global variables "
               (<code>'f8-storage-class)" and "
               (<code>'f16-storage-class)" have been added.")
         (<li> "Homogeneous storage classes must be implemented using homogeneous vectors, or be defined as "(<code>'#f)".")
         (<li> "The procedure "(<code>'make-interval)" now takes one or two arguments.")
         (<li> "Specialized arrays can be mutable or immutable; the default, which can be changed, is mutable. Shared arrays inherit safety and mutability from source arrays.")
         (<li> "The discussion of Haar transforms as examples of separable transforms has been corrected.")
         (<li> "The documentation has a few more examples of image processing algorithms.")
         (<li> "Some matrix examples have been added to this document."))


        (<h2> "Overview")
        (<h3> "Bawden-style arrays")
        (<p>  "In a "(<a> href: "https://groups.google.com/forum/?hl=en#!msg/comp.lang.scheme/7nkx58Kv6RI/a5hdsduFL2wJ" "1993 post")
              " to the news group comp.lang.scheme, Alan Bawden gave a simple implementation of multi-dimensional arrays in R4RS scheme. "
              "The only constructor of new arrays required specifying an initial value, and he provided the three low-level primitives "
              (<code>'array-ref)", "(<code>'array-set!)", and "(<code>'array?)", as well as "(<code>'make-array)" and "(<code>'make-shared-array)
              ".  His arrays were defined on rectangular intervals in "
              "$\\mathbb Z^d$ of the form $[l_0,u_0)\\times\\cdots\\times [l_{d-1},u_{d-1})$.  I'll note that his function "(<code>'array-set!)
              " put the value to be entered into the array at the front of the variable-length list of indices that indicate where to "
              "place the new value.  He offered an intriguing way to \"share\" arrays "
              "in the form of a routine "(<code>'make-shared-array)" that took a mapping from a new interval of indices into the domain "
              "of the array to be shared.  His implementation incorporated what he called an "(<i>'indexer)", which was a function from "
              "the interval $[l_0,u_0)\\times\\cdots\\times [l_{d-1},u_{d-1})$ to an interval $[0,N)$, where the "(<i>'body)" of the array consisted of "
              "a single Scheme vector of length $N$.  Bawden called the mapping specified in "(<code>'make-shared-array)" "
              (<i>'linear)", but I prefer the term "(<i>'affine)", as I explain later.")
        (<p> "Mathematically, Bawden's arrays can be described as follows.  We'll use the vector notation $\\vec i$ for a multi-index "
             "$i_0,\\ldots,i_{d-1}$. (Multi-indices correspond to Scheme "(<code>'values)".)  Arrays will be denoted by capital letters "
             "$A,B,\\ldots$, the domain of the array $A$ will be denoted by $D_A$, "
             "and the indexer of $A$, mapping $D_A$ to the interval $[0,N)$, will be denoted by $I_A$.  Initially, Bawden constructs "
             "$I_A$ such that $I_A(\\vec i)$ steps consecutively through the values $0,1,\\ldots,N-1$ as $\\vec i$ steps through the "
             "multi-indices $(l_0,\\ldots,l_{d-2},l_{d-1})$, $(l_0,\\ldots,l_{d-2},l_{d-1}+1)$, $\\ldots$, $(l_0,\\ldots,l_{d-2}+1,l_{d-1})$, etc., in lexicographical order, which means "
             "that if $\\vec i$ and $\\vec j$ are two multi-indices, then $\\vec i<\\vec j$ if and only if the least coordinate $k$ where $\\vec i$ and $\\vec j$ "
             "differ satisfies $\\vec i_k<\\vec j_k$.  This ordering of multi-indices is also known as "(<a> href: "https://en.wikipedia.org/w/index.php?title=Row-_and_column-major_order&oldid=995330290" "row-major order")
             ", which is used in the programming language C to order the elements of multi-dimensional arrays.  In contrast, the programming language Fortran uses column-major order to order the elements of multi-dimensional arrays.")
        (<p> "In "(<code>'make-shared-array)", Bawden allows you to specify a new $r$-dimensional interval $D_B$ as the domain of a new array $B$, and a "
             "mapping $T_{BA}:D_B\\to D_A$ of the form $T_{BA}(\\vec i)=M\\vec i+\\vec b$; here $M$ is a $d\\times r$ matrix of integer values and "
             "$\\vec b$ is a $d$-vector.  So this mapping $T_{BA}$ is "(<i>'affine)", in that $T_{BA}(\\vec i)-T_{BA}(\\vec j)=M(\\vec i-\\vec j)$ is "
             (<i>'linear)" (in a linear algebra sense) in $\\vec i-\\vec j$.  The new indexer of $B$ satisfies $I_B(\\vec i)=I_A(T_{BA}(\\vec i))$.")
        (<p> "A fact Bawden exploits in the code, but doesn't point out in the short post, is that $I_B$ is again an affine map, and indeed, the composition "
             "of "(<i>'any)" two affine maps is again affine.")
        (<h3> "Our extensions of Bawden-style arrays")
        (<p> "We incorporate Bawden-style arrays into this SRFI, but extend them in one minor way that we find useful.")
        (<p> "We introduce the notion of a "(<i>"storage class")", an object that contains functions that manipulate, store, check, etc., different types of values. "
             "A "(<code>'generic-storage-class)" can manipulate any Scheme value, "
             "whereas, e.g., a "(<code>'u1-storage-class)" can store only the values 0 and 1 in each element of a body.")
        (<p> "We also require that our affine maps be one-to-one, so that if $\\vec i\\neq\\vec j$ then $T(\\vec i)\\neq T(\\vec j)$.  Without this property, modifying "
             "the $\\vec i$th component of $A$ would cause the $\\vec j$th component to change.")
        (<h3> "Common transformations on Bawden-style arrays")
        (<p> "Requiring the transformations $T_{BA}:D_B\\to D_A$ to be affine may seem  esoteric and restricting, but in fact many common and useful array transformations "
             "can be expressed in this way.  We give several examples below: ")
        (<ul>
         (<li> (<b> "Restricting the domain of an array: ")
               "  If the domain of $B$, $D_B$, is a subset of the domain of $A$, then $T_{BA}(\\vec i)=\\vec i$ is a one-to-one affine mapping.  We define "
               (<code>'array-extract)" to define this common operation; it's like looking at a rectangular sub-part of a spreadsheet. We use it to extract the common part of overlapping domains of three arrays in an image processing example below. ")
         (<li> (<b> "Tiling an array: ")
               "For various reasons (parallel processing, optimizing cache localization, GPU programming, etc.) one may wish to process a large array as a number of subarrays of the same dimensions, which we call "(<i>'tiling)" the array.  The routine "(<code>'array-tile)" returns a new array, each entry of which is a subarray extracted (in the sense of "(<code>'array-extract)") from the input array.")
         (<li> (<b> "Translating the domain of an array: ")
               "If $\\vec d$ is a vector of integers, then $T_{BA}(\\vec i)=\\vec i-\\vec d$ is a one-to-one affine map of $D_B=\\{\\vec i+\\vec d\\mid \\vec i\\in D_A\\}$ onto $D_A$. "
               "We call $D_B$ the "(<i>'translate)" of $D_A$, and we define "(<code>'array-translate)" to provide this operation.")
         (<li> (<b> "Permuting the coordinates of an array: ")
               "If $\\pi$ "(<a> href: "https://en.wikipedia.org/wiki/Permutation" 'permutes)" the coordinates of a multi-index $\\vec i$, and $\\pi^{-1}$ is the inverse of $\\pi$, then "
               "$T_{BA}(\\vec i)=\\pi (\\vec i)$ is a one-to-one affine map from $D_B=\\{\\pi^{-1}(\\vec i)\\mid \\vec i\\in D_A\\}$ onto $D_A$.  We provide "(<code>'array-permute)" for this operation. "
               "(The only nonidentity permutation of a two-dimensional spreadsheet turns rows into columns and vice versa.) "
               "We also provide "(<code>'array-rotate)" for the special permutations that rotate the axes. For example, in three dimensions we have the following three rotations: $i\\ j\\ k\\to j\\ k\\ i$; $i\\ j\\ k\\to k\\ i\\ j$; and the trivial (identity) rotation $i\\ j\\ k\\to i\\ j\\ k$.  The three-dimensional permutations that are not rotations are $i\\ j\\ k\\to i\\ k\\ j$; $i\\ j\\ k\\to j\\ i\\ k$; and $i\\ j\\ k\\to k\\ j\\ i$.")
         (<li> (<b> "Currying an array: ")
               "Let's denote the cross product of two intervals $\\text{Int}_1$ and $\\text{Int}_2$ by $\\text{Int}_1\\times\\text{Int}_2$; "
               "if $\\vec j=(j_0,\\ldots,j_{r-1})\\in \\text{Int}_1$ and $\\vec i=(i_0,\\ldots,i_{s-1})\\in \\text{Int}_2$, then "
               "$\\vec j\\times\\vec i$, which we define to be $(j_0,\\ldots,j_{r-1},i_0,\\ldots,i_{s-1})$, is in $\\text{Int}_1\\times\\text{Int}_2$. "
               "If $D_A=\\text{Int}_1\\times\\text{Int}_2$ and $\\vec j\\in\\text{Int}_1$, then $T_{BA}(\\vec i)=\\vec j\\times\\vec i$ "
               "is a one-to-one affine mapping from $D_B=\\text{Int}_2$ into $D_A$.  For each vector $\\vec j$ we can compute a new array in this way; we provide "
               (<code>'array-curry)" for this operation, which returns an array whose domain is $\\text{Int}_1$ and whose elements are themselves arrays, each of which is defined on $\\text{Int}_2$. "
               "Currying a two-dimensional array would be like organizing a spreadsheet into a one-dimensional array of rows of the spreadsheet.")
         (<li> (<b> "Traversing some indices in a multi-index in reverse order: ")
               "Consider an array $A$ with domain $D_A=[l_0,u_0)\\times\\cdots\\times[l_{d-1},u_{d-1})$. Fix $D_B=D_A$ and assume we're given a vector of booleans $F$ ($F$ for \"flip?\"). "
               "Then define $T_{BA}:D_B\\to D_A$ by $i_j\\to i_j$ if $F_j$ is "(<code>'#f)" and $i_j\\to u_j+l_j-1-i_j$ if  $F_j$ is "(<code>'#t)". "
               "In other words,  we reverse the ordering of the $j$th coordinate of $\\vec i$ if and only if $F_j$ is true. "
               "$T_{BA}$ is an affine mapping from $D_B\\to D_A$, which defines a new array $B$, and we can provide "(<code>'array-reverse)" for this operation. "
               "Applying "(<code>'array-reverse)" to a two-dimensional spreadsheet might reverse the order of the rows or columns (or both).")
         (<li> (<b> "Uniformly sampling an array: ")
               "Assume that $A$ is an array with domain $[0,u_1)\\times\\cdots\\times[0,u_{d-1})$ (i.e., an interval all of whose lower bounds are zero). "
               "We'll also assume the existence of vector $S$ of scale factors, which are positive exact integers. "
               "Let $D_B$ be a new interval with $j$th lower bound equal to zero and $j$th upper bound equal to $\\operatorname{ceiling}(u_j/S_j)$ and let "
               "$T_{BA}(\\vec i)_j=i_j\\times S_j$, i.e., the $j$th coordinate is scaled by $S_j$.  ($D_B$ contains precisely those multi-indices that $T_{BA}$ maps into $D_A$.) "
               "Then $T_{BA}$ is an affine one-to-one mapping, and we provide "(<code>'interval-scale)" and "(<code>'array-sample)" for these operations.")
         )
        (<p> "We make several remarks.  First, all these operations could have been computed by specifying the particular mapping $T_{BA}$ explicitly, so that these routines are simply "
             "\"convenience\" procedures.  Second, because the composition of any number of affine mappings is again affine, accessing or changing the elements of a "
             "restricted, translated, curried, permuted array is no slower than accessing or changing the elements of the original array itself. "
             "Finally, we note that by combining array currying and permuting, say, one can come up with simple expressions of powerful algorithms, such as extending "
             "one-dimensional transforms to multi-dimensional separable transforms, or quickly generating two-dimensional slices of three-dimensional image data. "
             "Examples are given below.")

        (<h3> "Generalized arrays")
        (<p> "Bawden-style arrays are clearly useful as a programming construct, but they do not fulfill all our needs in this area. "
             "An array, as commonly understood, provides a mapping from multi-indices  $(i_0,\\ldots,i_{d-1})$ of exact integers
in a nonempty, rectangular, $d$-dimensional interval $[l_0,u_0)\\times[l_1,u_1)\\times\\cdots\\times[l_{d-1},u_{d-1})$ (the "(<i>'domain)" of the array) to Scheme objects.
Thus, two things are necessary to specify an array: an interval and a mapping that has that interval as its domain.")
        (<p> "Since these two things are often sufficient for certain algorithms, we introduce in this SRFI a minimal set of interfaces for dealing with such arrays.")
        (<p> "Specifically, an array specifies a nonempty, multi-dimensional interval, called its "(<i> "domain")", and a mapping from this domain to Scheme objects.  This mapping is called the "(<i> 'getter)" of the array, accessed with the procedure "(<code>'array-getter)"; the domain of the array (more precisely, the domain of the array's getter) is accessed with the procedure "(<code>'array-domain)".")
        (<p> "If this mapping can be changed, the array is said to be "(<i> 'mutable)" and the mutation is effected
by the array's "(<i> 'setter)", accessed by the procedure "(<code>'array-setter)".  We call an object of this type a mutable array. Note: If an array does not have a setter, then we call it immutable even though the array's getter might not be a \"pure\" function, i.e., the value it returns may not depend solely on the arguments passed to the getter.")
        (<p> "In general, we leave the implementation of generalized arrays completely open.  They may be defined simply by closures, or
they may have hash tables or databases behind an implementation, one may read the values from a file, etc.")
        (<p> "In this SRFI, Bawden-style arrays are called "(<i> 'specialized)". A specialized array is an example of a mutable array.")

        (<h3> "Sharing generalized arrays")
        (<p> "Even if an array $A$ is not a specialized array, then it could be \"shared\" by specifying a new interval $D_B$ as the domain of "
             "a new array $B$ and an affine map $T_{BA}:D_B\\to D_A$.  Each call to $B$ would then be computed as $B(\\vec i)=A(T_{BA}(\\vec i))$.")
        (<p> "One could again \"share\" $B$, given a new interval $D_C$ as the domain of a new array $C$ and an affine transform $T_{CB}:D_C\\to D_B$, and then each access $C(\\vec i)=A(T_{BA}(T_{CB}(\\vec i)))$.  The composition $T_{BA}\\circ T_{CB}:D_C\\to D_A$, being itself affine, could be precomputed and stored as $T_{CA}:D_C\\to D_A$, and $C(\\vec i)=A(T_{CA}(\\vec i))$ can be computed with the overhead of computing a single affine transformation.")
        (<p> "So, if we wanted, we could share generalized arrays with constant overhead by adding a single layer of (multi-valued) affine transformations on top of evaluating generalized arrays.  Even though this could be done transparently to the user, we do not do that here; it would be a compatible extension of this SRFI to do so.  We provide only the routine "(<code>'specialized-array-share)", not a more general "(<code>'array-share)".")
        (<p> "Certain ways of sharing generalized arrays, however, are relatively easy to code and not that expensive.  If we denote "(<code>"(array-getter A)")" by "(<code>'A-getter)", then if B is the result of "(<code>'array-extract)" applied to A, then "
             (<code>"(array-getter B)")" is simply "(<code>'A-getter)".  Similarly, if A is a two-dimensional array, and B is derived from A by applying the permutation $\\pi((i,j))=(j,i)$, then "(<code>"(array-getter B)")" is "
             (<code>"(lambda (i j) (A-getter j i))")".  Translation and currying also lead to transformed arrays whose getters are relatively efficiently derived from "(<code>'A-getter)", at least for arrays of small dimension.")
        (<p> "Thus, while we do not provide for sharing of generalized arrays for general one-to-one affine maps $T$, we do allow it for the specific functions "(<code>'array-extract)", "(<code>'array-translate)", "(<code>'array-permute)",  "
             (<code>'array-curry)",  "(<code>'array-reverse)", "(<code>'array-tile)", "(<code>'array-rotate)" and "(<code>'array-sample)",  and we provide relatively efficient implementations of these functions for arrays of dimension no greater than four.")
        (<h3> "Array-map does not produce a specialized array")
        (<p> "Daniel Friedman and David Wise wrote a famous paper "(<a> href: "http://www.cs.indiana.edu/cgi-bin/techreports/TRNNN.cgi?trnum=TR44" "CONS should not Evaluate its Arguments")". "
             "In the spirit of that paper, our procedure "(<code>'array-map)" does not immediately produce a specialized array, but a simple immutable array, whose elements are recomputed from the arguments of "(<code>'array-map)
             " each time they are accessed.   This immutable array can be passed on to further applications of "(<code>'array-map)" for further processing without generating the storage bodies for intermediate arrays.")
        (<p> "We provide the procedure "(<code>'array-copy)" to transform a generalized array (like that returned by "(<code>'array-map)
             ") to a specialized, Bawden-style array, for which accessing each element again takes $O(1)$ operations.")

        (<h3> "Notational convention")
        (<p> "If "(<code>(<var>'A))" is an array, then we generally define "(<code>(<var>'A_))" to be "(<code>"(array-getter "(<var>'A)")")" and  "(<code>(<var>'A!))" to be "(<code>"(array-setter "(<var>'A)")")".  The latter notation is motivated by the general Scheme convention that the names of functions that modify the contents of data structures end in "(<code>(<var>"!"))", while the notation for the getter of an array is motivated by the TeX notation for subscripts.  See particularly the "(<a> href: "#Haar" "Haar transform")" example.")





        (<h2> "Notes")
        (<ul>
         (<li> (<b> "Relationship to "(<a> href: "https://docs.racket-lang.org/math/array_nonstrict.html#%28tech._nonstrict%29" "nonstrict arrays")" in Racket. ")
               "It appears that what we call simply arrays in this SRFI are called nonstrict arrays in the math/array library of Racket, which in turn was influenced by an "(<a> href: "https://research.microsoft.com/en-us/um/people/simonpj/papers/ndp/RArrays.pdf" "array proposal for Haskell")".  Our \"specialized\" arrays are related to Racket's \"strict\" arrays.")
         (<li> (<b> "Indexers. ")"The argument "(<code>(<var> "new-domain->old-domain"))" to "(<code> 'specialized-array-share)" is, conceptually, a multi-valued array.")
         (<li> (<b> "Source of function names. ")"The function "(<code> 'array-curry)" gets its name from the" #\newline
               (<a> href: "https://en.wikipedia.org/wiki/Currying" "curry operator")
               " in programming" (string (integer->char 8212)) "we are currying the getter of the array and keeping careful track of the domains." #\newline
               (<code>'interval-projections)" can be thought of as currying the" #\newline
               "characteristic function of the interval,  encapsulated here as "(<code> 'interval-contains-multi-index?)".")
         (<li> (<b> "Choice of functions on intervals. ")"The choice of functions for both arrays and intervals was motivated almost solely by what I needed for arrays.")
         (<li> (<b> "No empty intervals. ")"This SRFI considers arrays over only nonempty intervals of positive dimension.  The author of this proposal acknowledges that other languages and array systems allow either zero-dimensional intervals or empty intervals of positive dimension, but prefers to leave such empty intervals as possibly compatible extensions to the current proposal.")
         (<li> (<b> "Multi-valued arrays. ")"While this SRFI restricts attention to single-valued arrays, wherein the getter of each array returns a single value, allowing multi-valued immutable arrays would be a compatible extension of this SRFI.")
         (<li> (<b> "No low-level specialized array constructor. ")
               "While the author of the SRFI uses mainly "(<code>"(make-array ...)")", "(<code>'array-map)", and "(<code>'array-copy)" to construct arrays, and while there are several other ways to construct arrays, there is no really low-level interface given for constructing specialized arrays (where one specifies a body, an indexer, etc.).  It was felt that certain difficulties, some surmountable (such as checking that a given body is compatible with a given storage class) and some not (such as checking that an indexer is indeed affine), made a low-level interface less useful.  At the same time, the simple "(<code>"(make-array ...)")" mechanism is so general, allowing one to specify getters and setters as general functions, as to cover nearly all needs.")

         )
        (<h2> "Specification")
        (let ((END ",\n"))
          (<p> "Names defined in this SRFI:")
          (<dl>
           (<dt> "Miscellaneous Functions")
           (<dd> (<a> href: "#translation?" "translation?") END
                 (<a> href: "#permutation?" "permutation?")
                 ".")
           (<dt> "Intervals")
           (<dd> (<a> href: "#make-interval" "make-interval")END
                 (<a> href: "#interval?" "interval?")END
                 (<a> href: "#interval-dimension" "interval-dimension")END
                 (<a> href: "#interval-lower-bound" "interval-lower-bound")END
                 (<a> href: "#interval-upper-bound" "interval-upper-bound")END
                 (<a> href: "#interval-lower-bounds-rarrow-list" "interval-lower-bounds->list")END
                 (<a> href: "#interval-upper-bounds-rarrow-list" "interval-upper-bounds->list")END
                 (<a> href: "#interval-lower-bounds-rarrow-vector" "interval-lower-bounds->vector")END
                 (<a> href: "#interval-upper-bounds-rarrow-vector" "interval-upper-bounds->vector")END
                 (<a> href: "#interval=" "interval=")END
                 (<a> href: "#interval-volume" "interval-volume")END
                 (<a> href: "#interval-subset?" "interval-subset?")END
                 (<a> href: "#interval-contains-multi-index?" "interval-contains-multi-index?")END
                 (<a> href: "#interval-projections" "interval-projections")END
                 (<a> href: "#interval-for-each" "interval-for-each")END
                 (<a> href: "#interval-dilate" "interval-dilate")END
                 (<a> href: "#interval-intersect" "interval-intersect")END
                 (<a> href: "#interval-translate" "interval-translate")END
                 (<a> href: "#interval-permute" "interval-permute") END
                 (<a> href: "#interval-rotate" "interval-rotate") END
                 (<a> href: "#interval-scale" "interval-scale") END
                 (<a> href: "#interval-cartesian-product" "interval-cartesian-product")
                 ".")
           (<dt> "Storage Classes")
           (<dd> (<a> href: "#make-storage-class" "make-storage-class") END
                 (<a> href: "#storage-class?" "storage-class?") END
                 (<a> href: "#storage-class-getter" "storage-class-getter") END
                 (<a> href: "#storage-class-setter" "storage-class-setter") END
                 (<a> href: "#storage-class-checker" "storage-class-checker") END
                 (<a> href: "#storage-class-maker" "storage-class-maker") END
                 (<a> href: "#storage-class-copier" "storage-class-copier") END
                 (<a> href: "#storage-class-length" "storage-class-length") END
                 (<a> href: "#storage-class-default" "storage-class-default") END
                 (<a> href: "#generic-storage-class" "generic-storage-class") END
                 (<a> href: "#s8-storage-class" "s8-storage-class") END
                 (<a> href: "#s16-storage-class" "s16-storage-class") END
                 (<a> href: "#s32-storage-class" "s32-storage-class") END
                 (<a> href: "#s64-storage-class" "s64-storage-class") END
                 (<a> href: "#u1-storage-class" "u1-storage-class") END
                 (<a> href: "#u8-storage-class" "u8-storage-class") END
                 (<a> href: "#u16-storage-class" "u16-storage-class") END
                 (<a> href: "#u32-storage-class" "u32-storage-class") END
                 (<a> href: "#u64-storage-class" "u64-storage-class") END
                 (<a> href: "#f8-storage-class" "f8-storage-class") END
                 (<a> href: "#f16-storage-class" "f16-storage-class") END
                 (<a> href: "#f32-storage-class" "f32-storage-class") END
                 (<a> href: "#f64-storage-class" "f64-storage-class") END
                 (<a> href: "#c64-storage-class" "c64-storage-class") END
                 (<a> href: "#c128-storage-class" "c128-storage-class")
                 ".")
           (<dt> "Arrays")
           (<dd> (<a> href: "#make-array" "make-array")END
                 (<a> href: "#array?" "array?")END
                 (<a> href: "#array-domain" "array-domain")END
                 (<a> href: "#array-getter" "array-getter")END
                 (<a> href: "#array-dimension" "array-dimension")END
                 (<a> href: "#mutable-array?" "mutable-array?")END
                 (<a> href: "#array-setter" "array-setter")END
                 (<a> href: "#specialized-array-default-safe?" "specialized-array-default-safe?") END
                 (<a> href: "#specialized-array-default-mutable?" "specialized-array-default-mutable?") END
                 (<a> href: "#make-specialized-array" "make-specialized-array")END
                 (<a> href: "#specialized-array?" "specialized-array?")END
                 (<a> href: "#array-storage-class" "array-storage-class")END
                 (<a> href: "#array-indexer" "array-indexer")END
                 (<a> href: "#array-body" "array-body")END
                 (<a> href: "#array-safe?" "array-safe?") END
                 (<a> href: "#array-elements-in-order?" "array-elements-in-order?") END
                 (<a> href: "#specialized-array-share" "specialized-array-share")END
                 (<a> href: "#array-copy" "array-copy")END
                 (<a> href: "#array-curry" "array-curry")END
                 (<a> href: "#array-extract" "array-extract") END
                 (<a> href: "#array-tile" "array-tile") END
                 (<a> href: "#array-translate" "array-translate")END
                 (<a> href: "#array-permute" "array-permute")END
                 (<a> href: "#array-rotate" "array-rotate")END
                 (<a> href: "#array-reverse" "array-reverse")END
                 (<a> href: "#array-sample" "array-sample")END
                 (<a> href: "#array-outer-product" "array-outer-product") END
                 (<a> href: "#array-map" "array-map")END
                 (<a> href: "#array-for-each" "array-for-each")END
                 (<a> href: "#array-fold" "array-fold")END
                 (<a> href: "#array-fold-right" "array-fold-right")END
                 (<a> href: "#array-reduce" "array-reduce") END
                 (<a> href: "#array-any" "array-any")END
                 (<a> href: "#array-every" "array-every")END
                 (<a> href: "#array-rarrow-list" "array->list") END
                 (<a> href: "#list-rarrow-array" "list->array") END
                 (<a> href: "#array-assign!" "array-assign!") END
                 (<a> href: "#array-ref" "array-ref") END
                 (<a> href: "#array-set!" "array-set!") END
                 (<a> href: "#specialized-array-reshape" "specialized-array-reshape")
                 "."
                 )))
        (<h2> "Miscellaneous Functions")
        (<p> "This document refers to "(<i> 'translations)" and "(<i> 'permutations)".
 A translation is a vector of exact integers.  A permutation of dimension $n$
is a vector whose entries are the exact integers $0,1,\\ldots,n-1$, each occurring once, in any order.")
        (<h3> "Procedures")
        (format-lambda-list '(translation? object))
        (<p> "Returns "(<code> '#t)" if "(<code>(<var>'object))" is a translation, and "(<code> '#f)" otherwise.")
        (format-lambda-list '(permutation? object))
        (<p> "Returns "(<code> '#t)" if "(<code>(<var>'object))" is a permutation, and "(<code> '#f)" otherwise.")
        (<h2> "Intervals")
        (<p> "An interval represents the set of all multi-indices of exact integers
$i_0,\\ldots,i_{d-1}$
satisfying
$l_0\\leq i_0<u_0,\\ldots,l_{d-1}\\leq i_{d-1}<u_{d-1}$,
where the "(<i>"lower bounds")"
$l_0,\\ldots,l_{d-1}$
and the "(<i>"upper bounds")"
$u_0,\\ldots,u_{d-1}$
are specified multi-indices of exact integers.  The positive integer $d$ is the "(<i>"dimension")"
of the interval.  It is required that
$l_0<u_0,\\ldots,l_{d-1}<u_{d-1}$.")
        (<p> "Intervals are a data type distinct from other Scheme data types.")

        (<h3> "Procedures")
        (format-lambda-list '(make-interval arg1 #!optional arg2))
        (<p> "Create a new interval. "(<code> (<var>"arg1"))" and "(<code> (<var>"arg2"))" (if given) are nonempty vectors (of the same length) of exact integers.")
        (<p> "If "(<code> (<var>"arg2"))" is not given, then the entries of "(<code> (<var>"arg1"))" must be positive, and they are taken as the "(<code>(<var>"upper-bounds"))" of the interval, and  "(<code> (<var>"lower-bounds"))" is set to a vector of the same length with exact zero entries.")
        (<p> "If "(<code> (<var>"arg2"))" is given, then "(<code> (<var>"arg1"))" is taken to be "(<code> (<var>"lower-bounds"))" and "(<code> (<var>"arg2"))" is taken to be "(<code> (<var>"upper-bounds"))", which must satisfy")
        (<pre>
         (<code>" (< (vector-ref "(<var>"lower-bounds")" i) (vector-ref "(<var>"upper-bounds")" i))"))
        (<p> " for
$0\\leq i<{}$"(<code>"(vector-length "(<var>"lower-bounds")")")".  It is an error if
"(<code>(<var>"lower-bounds"))" and "(<code>(<var>"upper-bounds"))" do not satisfy these conditions.")

        (format-lambda-list '(interval? obj))
        (<p> "Returns "(<code> "#t")" if "(<code> (<var>"obj"))" is an interval, and "(<code>"#f")" otherwise.")

        (format-lambda-list '(interval-dimension interval))
        (<p> "If "(<code>(<var>"interval"))" is an interval built with ")
        (<pre>
         (<code>"(make-interval "(<var>"lower-bounds")" "(<var>"upper-bounds")")"))
        (<p> "then "(<code> 'interval-dimension)" returns "(<code>"(vector-length "(<var>"lower-bounds")")")".  It is an error to call "(<code> 'interval-dimension)"
if "(<code>(<var>"interval"))" is not an interval.")

        (format-lambda-list '(interval-lower-bound interval i))
        (format-lambda-list '(interval-upper-bound interval i))
        (<p> "If "(<code>(<var>"interval"))" is an interval built with ")
        (<blockquote>
         (<code>"(make-interval "(<var>"lower-bounds")" "(<var>"upper-bounds")")"))
        (<p> "and "(<code>(<var>"i"))" is an exact integer that satisfies")
        (<blockquote>
         "$0 \\leq i<$ "(<code>"(vector-length "(<var>"lower-bounds")")")",")
        (<p> " then "(<code> 'interval-lower-bound)" returns
"(<code>"(vector-ref "(<var>"lower-bounds")" "(<var>"i")")")" and "(<code> 'interval-upper-bound)" returns
"(<code>"(vector-ref "(<var>"upper-bounds")" "(<var>"i")")")".  It is an error to call "(<code> 'interval-lower-bound)" or "(<code> 'interval-upper-bound)"
if "(<code>(<var>"interval"))" and "(<code>(<var>"i"))" do not satisfy these conditions.")


 (format-lambda-list '(interval-lower-bounds->list interval) 'interval-lower-bounds-rarrow-list)
 (format-lambda-list '(interval-upper-bounds->list interval) 'interval-upper-bounds-rarrow-list)
 (<p> "If "(<code>(<var>"interval"))" is an interval built with ")
 (<pre>
  (<code>"(make-interval "(<var>"lower-bounds")" "(<var>"upper-bounds")")"))
 (<p> " then "(<code> 'interval-lower-bounds->list)" returns "(<code> "(vector->list "(<var>"lower-bounds")")")
      " and  "(<code> 'interval-upper-bounds->list)" returns "(<code> "(vector->list "(<var>"upper-bounds")")")". It is an error to call
 "(<code> 'interval-lower-bounds->list)" or "(<code> 'interval-upper-bounds->list)" if "(<code>(<var>"interval"))" does not satisfy these conditions.")

        (format-lambda-list '(interval-lower-bounds->vector interval) 'interval-lower-bounds-rarrow-vector)
        (format-lambda-list '(interval-upper-bounds->vector interval) 'interval-upper-bounds-rarrow-vector)
        (<p> "If "(<code>(<var>"interval"))" is an interval built with ")
        (<pre>
         (<code>"(make-interval "(<var>"lower-bounds")" "(<var>"upper-bounds")")"))
        (<p> " then "(<code> 'interval-lower-bounds->vector)" returns a copy of "(<code> (<var>"lower-bounds"))
             "  and "(<code> 'interval-upper-bounds->vector)" returns a copy of "(<code> (<var>"upper-bounds"))". It is an error to call
"(<code> 'interval-lower-bounds->vector)" or "(<code> 'interval-upper-bounds->vector)" if "(<code>(<var>"interval"))" does not satisfy these conditions.")


        (format-lambda-list '(interval-volume interval))
        (<p> "If "(<code>(<var>"interval"))" is an interval built with ")
        (<pre>
         (<code>"(make-interval "(<var>"lower-bounds")" "(<var>"upper-bounds")")"))
        (<p> "then, assuming the existence of "(<code>'vector-map)", "(<code> 'interval-volume)" returns ")
        (<pre>
         (<code> "(apply * (vector->list (vector-map - "(<var>"upper-bounds")" "(<var>"lower-bounds")")))"))


        (<p> "It is an error to call "(<code> 'interval-volume)" if "(<code>(<var> 'interval))" does not satisfy this condition.")

        (format-lambda-list '(interval= interval1 interval2))
        (<p> "If "(<code>(<var>"interval1"))" and "(<code>(<var>"interval2"))" are intervals built with ")
        (<pre>
         (<code>"(make-interval "(<var>"lower-bounds1")" "(<var>"upper-bounds1")")"))
        (<p> "and")
        (<pre>
         (<code>"(make-interval "(<var>"lower-bounds2")" "(<var>"upper-bounds2")")"))
        (<p> "respectively, then "(<code> 'interval=)" returns")
        (<pre>
         (<code> "(and (equal? "(<var> 'lower-bounds1)" "(<var> 'lower-bounds2)") (equal? "(<var> 'upper-bounds1)" "(<var> 'upper-bounds2)"))"))
        (<p> "It is an error to call "(<code> 'interval=)" if "(<code>(<var> 'interval1))" or "(<code>(<var> 'interval2))" do not satisfy this condition.")

        (format-lambda-list '(interval-subset? interval1 interval2))
        (<p> "If "(<code>(<var>"interval1"))" and "(<code>(<var>"interval2"))" are intervals of the same dimension $d$, "
             "then "(<code>'interval-subset?)" returns "(<code>'#t)" if ")
        (<pre>
         (<code>"(>= (interval-lower-bound "(<var>'interval1)" j) (interval-lower-bound "(<var>'interval2)" j))"))
        (<p> "and")
        (<pre>
         (<code>"(<= (interval-upper-bound "(<var>'interval1)" j) (interval-upper-bound "(<var>'interval2)" j))"))
        (<p> "for all $0\\leq j<d$, otherwise it returns "(<code>'#f)".  It is an error if the arguments do not satisfy these conditions.")

        (format-lambda-list '(interval-contains-multi-index? interval index-0 index-1 ...))
        (<p> "If "(<code>(<var> 'interval))" is an interval with dimension $d$ and "(<code>(<var> 'index-0))", "(<code>(<var> 'index-1))", ..., is a multi-index of length $d$,
then "(<code> 'interval-contains-multi-index?)" returns "(<code> #t)" if ")
        (<blockquote>
         (<code> "(interval-lower-bound "(<var> 'interval)" j)")" $\\leq$ "(<code> (<var> 'index-j))" $<$ "(<code> "(interval-upper-bound "(<var> 'interval)" j)"))
        (<p>"for $0\\leq j < d$, and "(<code>'#f)" otherwise.")
        (<p> "It is an error to call "(<code> 'interval-contains-multi-index?)" if "(<code>(<var> 'interval))" and "(<code>(<var> 'index-0))",..., do not satisfy this condition.")

        (format-lambda-list '(interval-projections interval right-dimension))
        (<p> "Conceptually, "(<code> 'interval-projections)" takes a $d$-dimensional interval
$[l_0,u_0)\\times [l_1,u_1)\\times\\cdots\\times[l_{d-1},u_{d-1})$\n"
             "and splits it into two parts")
        (<blockquote> "$[l_0,u_0)\\times\\cdots\\times[l_{d-\\text{right-dimension}-1},u_{d-\\text{right-dimension}-1})$")
        (<p> "and")
        (<blockquote> "$[l_{d-\\text{right-dimension}},u_{d-\\text{right-dimension}})\\times\\cdots\\times[l_{d-1},u_{d-1})$")
        (<p> "This function, the inverse of Cartesian products or cross products of intervals, is used to keep track of the domains of curried arrays.")
        (<p> "More precisely, if "(<code>(<var> 'interval))" is an interval and "(<code>(<var> 'right-dimension))" is an exact integer that satisfies "
             (<code> "0 < "(<var> 'right-dimension)" < "(<var>'d))" then "(<code> 'interval-projections)" returns two intervals:")
        (<pre>
         (<code> "
(values
 (make-interval
  (vector (interval-lower-bound "(<var>'interval)" 0)
          ...
          (interval-lower-bound "(<var>'interval)"
                                (- "(<var>'d)" "(<var>'right-dimension)" 1)))
  (vector (interval-upper-bound "(<var>'interval)" 0)
          ...
          (interval-upper-bound "(<var>'interval)"
                                (- "(<var>'d)" "(<var>'right-dimension)" 1))))
 (make-interval
  (vector (interval-lower-bound "(<var>'interval)"
                                (- "(<var>'d)" "(<var>'right-dimension)"))
          ...
          (interval-lower-bound "(<var>'interval)"
                                (- "(<var>'d)" 1)))
  (vector (interval-upper-bound "(<var>'interval)"
                                (- "(<var>'d)" "(<var>'right-dimension)"))
          ...
          (interval-upper-bound "(<var>'interval)"
                                (- "(<var>'d)" 1)))))"))
(<p> "It is an error to call "(<code> 'interval-projections)" if its arguments do not satisfy these conditions.")


(format-lambda-list '(interval-for-each f interval))
(<p> "This routine assumes that "(<code>(<var> 'interval))" is an interval and "(<code>(<var> 'f))" is a routine whose domain includes elements of "(<code>(<var> 'interval))".  It is an error to call
"(<code> 'interval-for-each)" if "(<code>(<var> 'interval))" and "(<code>(<var> 'f))" do not satisfy these conditions.")
(<p>  (<code> 'interval-for-each)" calls "(<code>(<var> 'f))" with each multi-index of "(<code>(<var> 'interval))" as arguments, all in lexicographical order.")



(format-lambda-list '(interval-dilate interval lower-diffs upper-diffs))
(<p> "If "(<code>(<var> 'interval))" is an interval with
lower bounds $\\ell_0,\\dots,\\ell_{d-1}$ and
upper bounds $u_0,\\dots,u_{d-1}$, and "
(<code>(<var> "lower-diffs"))" is a vector of exact integers $L_0,\\dots,L_{d-1}$ and "
(<code>(<var> "upper-diffs"))" is a vector of exact integers $U_0,\\dots,U_{d-1}$, then "
(<code>"interval-dilate")" returns a new interval with
lower bounds $\\ell_0+L_0,\\dots,\\ell_{d-1}+L_{d-1}$ and
upper bounds $u_0+U_0,\\dots,u_{d-1}+U_{d-1}$, as long as this is a
nonempty interval.  It is an error if the arguments do not satisfy these conditions.")
(<p> "Examples:")
(<pre>(<code>"
(interval=
 (interval-dilate (make-interval '#(100 100))
                  '#(1 1) '#(1 1))
 (make-interval '#(1 1) '#(101 101))) => #t
(interval=
 (interval-dilate (make-interval '#(100 100))
                  '#(-1 -1) '#(1 1))
 (make-interval '#(-1 -1) '#(101 101))) => #t
(interval=
 (interval-dilate (make-interval '#(100 100))
                  '#(0 0) '#(-50 -50))
 (make-interval '#(50 50))) => #t
(interval-dilate
 (make-interval '#(100 100))
 '#(0 0) '#(-500 -50)) => error
"))

(format-lambda-list '(interval-intersect interval-1 interval-2 ...))
(<p> "If all the arguments are intervals of the same dimension and they have a nonempty intersection,
then "(<code> 'interval-intersect)" returns that intersection; otherwise it returns "(<code>'#f)".")
(<p> "It is an error if the arguments are not all intervals with the same dimension.")

(format-lambda-list '(interval-translate interval translation))
(<p> "If "(<code>(<var> 'interval))" is an interval with
lower bounds $\\ell_0,\\dots,\\ell_{d-1}$ and
upper bounds $u_0,\\dots,u_{d-1}$, and "
(<code>(<var> "translation"))" is a translation with entries $T_0,\\dots,T_{d-1}$
, then "
(<code>"interval-translate")" returns a new interval with
lower bounds $\\ell_0+T_0,\\dots,\\ell_{d-1}+T_{d-1}$ and
upper bounds $u_0+T_0,\\dots,u_{d-1}+T_{d-1}$.
It is an error if the arguments do not satisfy these conditions.")
(<p> "One could define "(<code> "(interval-translate interval translation)")" by "(<code> "(interval-dilate interval translation translation)")".")

(format-lambda-list '(interval-permute interval permutation))
(<p> "The argument "(<code>(<var>'interval))" must be an interval, and the argument "(<code>(<var>'permutation))" must be a valid permutation with the same dimension as "(<code>(<var>'interval))".  It is an error if the arguments do not satisfy these conditions.")
(<p> "Heuristically, this function returns a new interval whose axes have been permuted in a way consistent with "(<code>(<var>'permutation))".
But we have to say how the entries of "(<code>(<var>'permutation))" are associated with the new interval.")
(<p> "We have chosen the following convention: If the permutation is $(\\pi_0,\\ldots,\\pi_{d-1})$, and the argument interval
represents the cross product
$[l_0,u_0)\\times[l_1,u_1)\\times\\cdots\\times[l_{d-1},u_{d-1})$,
then the result represents the cross product
$[l_{\\pi_0},u_{\\pi_0})\\times[l_{\\pi_1},u_{\\pi_1})\\times\\cdots\\times[l_{\\pi_{d-1}},u_{\\pi_{d-1}})$.")
(<p> "For example, if the argument interval represents $[0,4)\\times[0,8)\\times[0,21)\\times [0,16)$ and the
permutation is "(<code>'#(3 0 1 2))", then the result of "(<code> "(interval-permute "(<var>'interval)" "(<var>' permutation)")")" will be
the representation of $[0,16)\\times [0,4)\\times[0,8)\\times[0,21)$.")

(format-lambda-list '(interval-rotate interval dim))
(<p> "Informally, "(<code> "(interval-rotate "(<var>'interval)" "(<var>'dim)")")" rotates the axes of "(<code>(<var>'interval))" "(<code>(<var>'dim))" places to the left.")
(<p> "More precisely, "(<code> "(interval-rotate "(<var>'interval)" "(<var> 'dim)")")" assumes that "(<code>(<var>'interval))" is an interval and "(<code>(<var>'dim))" is an exact integer between 0 (inclusive) and "(<code> "(interval-dimension "(<var>'interval)")")" (exclusive).  It computes the permutation "(<code>"(vector "(<var>'dim)" ... (- (interval-dimension "(<var>'interval)") 1) 0 ... (- "(<var>'dim)" 1))")" (unless "(<code>(<var>'dim))" is zero, in which case it constructs the identity permutation) and returns "(<code>"(interval-permute "(<var>'interval)" "(<var>'permutation)")")". It is an error if the arguments do not satisfy these conditions.")


(format-lambda-list '(interval-scale interval scales))
(<p> "If "(<code>(<var>'interval))" is a $d$-dimensional interval $[0,u_1)\\times\\cdots\\times[0,u_{d-1})$ with all lower bounds zero, "
     "and "(<code>(<var>'scales))" is a length-$d$ vector of positive exact integers, which we'll denote by $\\vec s$, then "(<code>'interval-scale)
     " returns the interval $[0,\\operatorname{ceiling}(u_1/s_1))\\times\\cdots\\times[0,\\operatorname{ceiling}(u_{d-1}/s_{d-1}))$.")
(<p> "It is an error if  "(<code>(<var>'interval))" and "(<code>(<var>'scales))" do not satisfy this condition.")

(format-lambda-list '(interval-cartesian-product interval #\. intervals))
(<p> "Implements the Cartesian product of the intervals in "
     (<code>
      "(cons "
      (<var>'interval)
      " "
      (<var>'intervals)
      ")")". Returns")
(<pre>(<code>"
(make-interval (list->vector (apply append (map interval-lower-bounds->list (cons interval intervals))))
               (list->vector (apply append (map interval-upper-bounds->list (cons interval intervals)))))"))
(<p> "It is an error if any argument is not an interval.")

(<h2> "Storage classes")
(<p> "Conceptually, a storage-class is a set of functions to manage the backing store of a specialized array.
The functions allow one to make a backing store, to get values from the store and to set new values, to return the length of the store, and to specify a default value for initial elements of the backing store.  Typically, a backing store is a (heterogeneous or homogeneous) vector.  A storage-class has a type distinct from other Scheme types.")
(<h3> "Procedures")

(format-lambda-list '(make-storage-class getter setter checker maker copier length default))
(<p> "Here we assume the following relationships between the arguments of "(<code> 'make-storage-class)".  Assume that the \"elements\" of
the backing store are of some \"type\", either heterogeneous (all Scheme types) or homogeneous (of some restricted type).")
(<ul>
 (<li> (<code> "("(<var>"maker n")" "(<var> 'value)")")" returns a linearly addressed object containing "(<code>(<var> 'n))" elements of value "(<code>(<var> 'value))".")
 (<li> (<var>'copier)" may be #f or a procedure; if a procedure then if "(<code>(<var>'to))" and "(<code>(<var>'from))" were created by "(<code>(<var>'maker))", then "(<code>"("(<var> "copier to at from start end")")")" copies elements from "(<code>(<var>'from))" beginning at "(<code>(<var>'start))" (inclusive) and ending at "(<code>(<var>'end))" (exclusive) to "(<code>(<var>'to))" beginning at "(<code>(<var>'at))".  It is assumed that all the indices involved are within the domain of "(<code>(<var>'from))" and "(<code>(<var>'to))", as needed.  The order in which the elements are copied is unspecified.")
 (<li> "If "(<code>(<var> 'v))" is an object created by "
       (<code>"("(<var> "maker n value")")")
       " and  0 <= "(<code>(<var> 'i))" < "(<code>(<var> 'n))", then "(<code> "("(<var>"getter v i")")")" returns the current value of the "(<code>(<var> 'i))"'th element of "(<code>(<var> 'v))", and "(<code> "("(<var> 'checker)" ("(<var>"getter v i")")) => #t")".")
 (<li> "If "(<code>(<var> 'v))" is an object created by "
       (<code>"("(<var> "maker n value")")")
       ",  0 <= "(<code>(<var> 'i))" < "(<code>(<var> 'n))", and "(<code>"("(<var> 'checker)" "(<var> 'val)") => #t")", then "(<code> "("(<var>"setter v i val")")")" sets the value of the "(<code>(<var> 'i))"'th element of  "(<code>(<var> 'v))" to "(<code>(<var> 'val))".")
 (<li> "If "(<code>(<var> 'v))" is an object created by "
       (<code>"("(<var> "maker n value")")")
       " then "(<code> "("(<var>"length v")")")" returns "(<code>(<var> 'n))"."))
(<p> "If the arguments do not satisfy these conditions, then it is an error to call "(<code> 'make-storage-class)".")
(<p> "Note that we assume that "(<code>(<var> 'getter))" and "(<code>(<var> 'setter))" generally take "(<i> 'O)"(1) time to execute.")

(format-lambda-list '(storage-class? m))
(<p> "Returns "(<code>'#t)" if "(<code>(<var>'m))" is a storage class, and "(<code>'#f)" otherwise.")

(format-lambda-list '(storage-class-getter m))
(format-lambda-list '(storage-class-setter m))
(format-lambda-list '(storage-class-checker m))
(format-lambda-list '(storage-class-maker m))
(format-lambda-list '(storage-class-copier m))
(format-lambda-list '(storage-class-length m))
(format-lambda-list '(storage-class-default m))
(<p> "If "(<code>(<var> 'm))" is an object created by")
(<blockquote>
 (<code>"(make-storage-class "(<var> "getter setter checker maker copier length default")")"))
(<p> " then "
     (<code> 'storage-class-getter)" returns "(<code>(<var> 'getter))", "
     (<code> 'storage-class-setter)" returns "(<code>(<var> 'setter))", "
     (<code> 'storage-class-checker)" returns "(<code>(<var> 'checker))", "
     (<code> 'storage-class-maker)" returns "(<code>(<var> 'maker))", "
     (<code> 'storage-class-copier)" returns "(<code>(<var> 'copier))", "
     (<code> 'storage-class-length)" returns "(<code>(<var> 'length))", and "
     (<code> 'storage-class-default)" returns "(<code>(<var> 'default))".  Otherwise, it is an error to call any of these routines.")

(<h3> "Global Variables")
(format-global-variable 'generic-storage-class)
(format-global-variable 's8-storage-class)
(format-global-variable 's16-storage-class)
(format-global-variable 's32-storage-class)
(format-global-variable 's64-storage-class)
(format-global-variable 'u1-storage-class)
(format-global-variable 'u8-storage-class)
(format-global-variable 'u16-storage-class)
(format-global-variable 'u32-storage-class)
(format-global-variable 'u64-storage-class)
(format-global-variable 'f8-storage-class)
(format-global-variable 'f16-storage-class)
(format-global-variable 'f32-storage-class)
(format-global-variable 'f64-storage-class)
(format-global-variable 'c64-storage-class)
(format-global-variable 'c128-storage-class)

(<p> (<code> 'generic-storage-class)" is defined as if by")
(<pre>
 (<code> "
(define generic-storage-class
  (make-storage-class vector-ref
                      vector-set!
                      (lambda (arg) #t)
                      make-vector
                      vector-copy!
                      vector-length
                      #f))"))
(<p> "Implementations shall define "(<code> "s"(<var> 'X)"-storage-class")" for "(<code>(<var> 'X))"=8, 16, 32, and 64 (which have default values 0 and
manipulate exact integer values between -2"(<sup>(<var> 'X)"-1")" and
2"(<sup> (<var> 'X)"-1")"-1 inclusive),
 "(<code> "u"(<var> 'X)"-storage-class")" for "(<code>(<var> 'X))"=1, 8, 16, 32, and 64 (which have default values 0 and manipulate exact integer values between 0 and
2"(<sup> (<var> 'X))"-1 inclusive),
"(<code> "f"(<var> 'X)"-storage-class")" for "(<code>(<var> 'X))"= 8, 16, 32, and 64 (which have default value 0.0 and manipulate 8-, 16-, 32-, and 64-bit floating-point numbers), and
"(<code> "c"(<var> 'X)"-storage-class")" for "(<code>(<var> 'X))"= 64 and 128 (which have default value 0.0+0.0i and manipulate complex numbers with, respectively, 32- and 64-bit floating-point numbers as real and imaginary parts).")
(<p> "Implementations with an appropriate homogeneous vector type should define the associated global variable using "(<code>'make-storage-class)", otherwise they shall define the associated global variable to "(<code>'#f)".")

(<h2> "Arrays")
(<p> "Arrays are a data type distinct from other Scheme data types.")

(<h3> "Procedures")

(format-lambda-list '(make-array interval getter #\[ setter #\]))
(<p> "Assume first that the optional argument "(<code>'setter)" is not given.")
(<p> "If "(<code>(<var> 'interval))" is an interval and "(<code>(<var> 'getter))" is a function from
"(<code>(<var> 'interval))" to Scheme objects, then "(<code> 'make-array)" returns an array with domain "(<code>(<var> 'interval))"
and getter "(<code>(<var> 'getter))".")
(<p> "It is an error to call "(<code> 'make-array)" if "(<code>(<var> 'interval))" and "(<code>(<var> 'getter))"
do not satisfy these conditions.")
(<p> "If now "(<code>(<var> 'setter))" is specified, assume that it is a procedure such that getter and setter satisfy: If")
(<blockquote>
 (<code>"("(<var> 'i)(<sub> '1)",...,"(<var> 'i)(<sub> 'n)")")" $\\neq$ "(<code> "("(<var> 'j)(<sub> '1)",...,"(<var> 'j)(<sub> 'n)")"))
(<p> "are elements of "(<code>(<var> 'interval))" and ")
(<blockquote>
 (<code> "(getter "(<var> 'j)(<sub> '1)" ... "(<var> 'j)(<sub> 'n)") => x"))
(<p> "then \"after\"")
(<blockquote>
 (<code> "(setter v "(<var> 'i)(<sub> '1)" ... "(<var> 'i)(<sub> 'n)")"))
(<p> "we have")
(<blockquote>
 (<code> "(getter "(<var> 'j)(<sub> '1)" ... "(<var> 'j)(<sub> 'n)") => x"))
(<p> "and")
(<blockquote>
 (<code> "(getter "(<var> 'i)(<sub> '1)",...,"(<var> 'i)(<sub> 'n)") => v"))
(<p> "Then "(<code> 'make-array)" builds a mutable array with domain "(<code>(<var> 'interval))", getter "(<code>(<var> 'getter))", and
setter "(<code>(<var> 'setter))".  It is an error to call "(<code> 'make-array)" if its arguments do not satisfy these conditions.")


(<p> "Example: ")
(<pre>
 (<code>"
  (define a (make-array (make-interval '#(1 1) '#(11 11))
                        (lambda (i j)
                          (if (= i j)
                              1
                              0))))"))
(<p> "defines an array for which "(<code> "(array-getter a)")" returns 1 when i=j and 0 otherwise.")

(<p> "Example: ")
(<pre>
 (<code>"
(define a   ;; a sparse array
  (let ((domain
         (make-interval '#(1000000 1000000)))
        (sparse-rows
         (make-vector 1000000 '())))
    (make-array
     domain
     (lambda (i j)
       (cond ((assv j (vector-ref sparse-rows i))
              => cdr)
             (else
              0.0)))
     (lambda (v i j)
       (cond ((assv j (vector-ref sparse-rows i))
              => (lambda (pair)
                   (set-cdr! pair v)))
             (else
              (vector-set!
               sparse-rows
               i
               (cons (cons j v)
                     (vector-ref sparse-rows i)))))))))

(define a_ (array-getter a))
(define a! (array-setter a))

(a_ 12345 6789)  => 0.
(a_ 0 0) => 0.
(a! 1.0 0 0) => undefined
(a_ 12345 6789)  => 0.
(a_ 0 0) => 1."))

(format-lambda-list '(array? obj))
(<p> "Returns "(<code> "#t")" if  "(<code>(<var> 'obj))" is an array and "(<code> '#f)" otherwise.")

(format-lambda-list '(array-domain array))
(format-lambda-list '(array-getter array))
(<p> "If "(<code>(<var> 'array))" is an array built by")
(<pre>
 (<code> "(make-array "(<var> 'interval)" "(<var> 'getter)" ["(<var> 'setter)"])"))
(<p> "(with or without the optional "(<code>(<var> 'setter))" argument) then "(<code> 'array-domain)" returns "(<code>(<var> 'interval))
     " and "(<code> 'array-getter)" returns  "(<code>(<var> 'getter))".
It is an error to call "(<code> 'array-domain)" or "(<code> 'array-getter)" if "(<code>(<var> 'array))" is not an array.")
(<p> "Example: ")
(<pre>
 (<code>"
(define a (make-array (make-interval '#(1 1) '#(11 11))
                      (lambda (i j)
                        (if (= i j)
                            1
                            0))))
(define a_ (array-getter a))

(a_ 3 3) => 1
(a_ 2 3) => 0
(a_ 11 0) => is an error"))

(format-lambda-list '(array-dimension array))
(<p> "Shorthand for "(<code>"(interval-dimension (array-domain "(<var>'array)"))")".  It is an error to call this function if "(<code>(<var>'array))" is not an array.")

(format-lambda-list '(mutable-array? obj))
(<p> "Returns "(<code>"#t")" if "(<code>(<var> 'obj))" is a mutable array and "(<code> '#f)" otherwise.")

(format-lambda-list '(array-setter array))
(<p> "If "(<code>(<var> 'array))" is an array built by")
(<pre>
 (<code> "(make-array "(<var> 'interval)" "(<var> 'getter)" "(<var> 'setter)")"))
(<p> "then "(<code> 'array-setter)" returns "(<code>(<var> 'setter))". It is an error to call "(<code> 'array-setter)"
if "(<code>(<var> 'array))" is not a mutable array.")

(format-lambda-list '(specialized-array-default-safe? #\[ bool #\]))
(<p> "With no argument, returns "(<code>'#t)" if newly constructed specialized arrays check the arguments of setters and getters by default, and "(<code>'#f)" otherwise.")
(<p> "If "(<code>(<var>'bool))" is "(<code>'#t)" then the next call to "(<code>'specialized-array-default-safe?)" will return "(<code>'#t)";
if "(<code>(<var>'bool))" is "(<code>'#f)" then the next call to "(<code>'specialized-array-default-safe?)" will return "(<code>'#f)";
otherwise it is an error.")
(<p> "Initially, "(<code> "(specialized-array-default-safe?)")" returns "(<code>'#f)".")

(format-lambda-list '(specialized-array-default-mutable? #\[ bool #\]))
(<p> "With no argument, returns "(<code>'#t)" if newly constructed specialized arrays are mutable by default, and "(<code>'#f)" otherwise.")
(<p> "If "(<code>(<var>'bool))" is "(<code>'#t)" then the next call to "(<code>'specialized-array-default-mutable?)" will return "(<code>'#t)";
if "(<code>(<var>'bool))" is "(<code>'#f)" then the next call to "(<code>'specialized-array-default-mutable?)" will return "(<code>'#f)";
otherwise it is an error.")
(<p> "Initially, "(<code> "(specialized-array-default-mutable?)")" returns "(<code>'#t)".")


(format-lambda-list '(make-specialized-array interval #\[ storage-class "generic-storage-class" #\] #\[ safe? "(specialized-array-default-safe?)"#\]))
(<p> "Constructs a mutable specialized array from its arguments.")
(<p> (<code>(<var>'interval))" must be given as a nonempty interval. If given, "(<code>(<var>'storage-class))" must be a storage class; if it is not given it defaults to "(<code>'generic-storage-class)". If given, "(<code>(<var>'safe?))" must be a boolean; if it is not given it defaults to the current value of "(<code>"(specialized-array-default-safe?)")".")

(<p>"The body of the result is constructed as ")
(<pre>
 (<code>"
  ((storage-class-maker "(<var>'storage-class)")
   (interval-volume "(<var>'interval)")
   (storage-class-default "(<var>'storage-class)"))
  "))
(<p> "The indexer of the resulting array is constructed as the lexicographical mapping of "(<code>(<var>'interval))" onto the interval "(<code> "[0,(interval-volume "(<var>'interval)"))")".")

(<p> "If "(<code>(<var>'safe))" is "(<code>'#t)", then the arguments of the getter and setter (including the value to be stored) of the resulting array are always checked for correctness.")
(<p> "After correctness checking (if needed), "(<code>"(array-getter "(<var>'array)")")" is defined simply as ")
(<pre>
 (<code>"
  (lambda multi-index
    ((storage-class-getter "(<var>'storage-class)")
     (array-body "(<var>'array)")
     (apply (array-indexer "(<var>'array)") multi-index)))
  "))
(<p> " and "(<code>"(array-setter "(<var>'array)")")" is defined as ")
(<pre>
 (<code>"
  (lambda (val . multi-index)
    ((storage-class-setter "(<var>'storage-class)")
     (array-body "(<var>'array)")
     (apply (array-indexer "(<var>'array)") multi-index)
     val))
  "
     ))
(<p> "It is an error if the arguments of "(<code>'make-specialized-array)" do not satisfy these conditions.")
(<p> (<b> "Examples. ")"A simple array that can hold any type of element can be defined with "(<code>"(make-specialized-array (make-interval '#(3 3)))")".  If you find that you're using a lot of unsafe arrays of unsigned 16-bit integers, one could define ")
(<pre>
 (<code>"
  (define (make-u16-array interval)
    (make-specialized-array interval u16-storage-class #f))
"))
(<p> "and then simply call, e.g., "(<code>"(make-u16-array (make-interval '#(3 3)))")".")

(format-lambda-list '(specialized-array? obj))
(<p> "Returns "(<code>"#t")" if "(<code>(<var> 'obj))" is a specialized-array, and "(<code>"#f")" otherwise. A specialized-array is an array.")
(format-lambda-list '(array-storage-class array))
(format-lambda-list '(array-indexer array))
(format-lambda-list '(array-body array))
(format-lambda-list '(array-safe? array))
(<p> (<code>'array-storage-class)" returns the storage-class of "(<code>(<var> 'array))". "
     (<code>'array-safe?)" is true if and only if the arguments of "(<code> "(array-getter "(<var> 'array)")")" and "(<code> "(array-setter "(<var> 'array)")")" (including the value to be stored in the array) are checked for correctness.")
(<p> (<code>"(array-body "(<var>'array)")")" is a linearly indexed, vector-like object (e.g., a vector, string, u8vector, etc.) indexed from 0.")
(<p> (<code>"(array-indexer "(<var> 'array)")")" is assumed to be a one-to-one, but not necessarily onto,  affine mapping from "(<code> "(array-domain "(<var> 'array)")")" into  the indexing domain of "(<code>"(array-body "(<var> 'array)")")".")
(<p> "Please see "(<a> href: "#make-specialized-array" (<code>'make-specialized-array))" for how "(<code>"(array-body "(<var>'array)")")", etc., are used.")
(<p> "It is an error to call any of these routines if "(<code>(<var> 'array))" is not a specialized array.")

(format-lambda-list '(array-elements-in-order? A))
(<p> "Assumes that "(<code>(<var>'A))" is a specialized array, in which case it returns "(<code>'#t)" if the elements of "(<code>(<var>'A))" are in order and stored adjacently in "(<code>"(array-body "(<var>'A)")")" and "(<code>'#f)" otherwise.")
(<p> "It is an error if "(<code>(<var>'A))" is not a specialized array.")

(format-lambda-list '(specialized-array-share array new-domain new-domain->old-domain))
(<p> "Constructs a new specialized array that shares the body of the specialized array "(<code>(<var> 'array))".
Returns an object that is behaviorally equivalent to a specialized array with the following fields:")
(<pre>
 (<code>"
domain:        new-domain
storage-class: (array-storage-class "(<var> 'array)")
body:          (array-body "(<var> 'array)")
indexer:       (lambda multi-index
                 (call-with-values
                     (lambda ()
                       (apply "(<var>'new-domain->old-domain)"
                              multi-index))
                   (array-indexer "(<var> 'array)")))"))

(<p> "The resulting array inherits its safety and mutability from "(<code>(<var>'array))".")

(<p> "Note: It is assumed that the affine structure of the composition of "(<code>(<var> 'new-domain->old-domain))" and "(<code>"(array-indexer "(<var> 'array)")")" will be used to simplify:")
(<pre>
 (<code>"
  (lambda multi-index
    (call-with-values
        (lambda ()
          (apply "(<var>'new-domain->old-domain)" multi-index))
      (array-indexer "(<var> 'array)")))"
      ))
(<p> "It is an error if "(<code>(<var>'array))" is not a specialized array, or if "(<code>(<var>'new-domain))" is not an interval, or if "(<code>(<var>'new-domain->old-domain))" is not a one-to-one affine mapping from "(<code>(<var> 'new-domain))" to
"(<code>"(array-domain "(<var> 'array)")")".")

(<p> (<b> "Example: ")
     "One can apply a \"shearing\" operation to an array as follows: ")
(<pre>
 (<code>"
(define a
  (array-copy
   (make-array (make-interval '#(5 10))
               list)))
(define b
  (specialized-array-share
   a
   (make-interval '#(5 5))
   (lambda (i j)
     (values i (+ i j)))))
;; Print the \"rows\" of b
(array-for-each (lambda (row)
                  (pretty-print (array->list row)))
                (array-curry b 1))

;; which prints
;; ((0 0) (0 1) (0 2) (0 3) (0 4))
;; ((1 1) (1 2) (1 3) (1 4) (1 5))
;; ((2 2) (2 3) (2 4) (2 5) (2 6))
;; ((3 3) (3 4) (3 5) (3 6) (3 7))
;; ((4 4) (4 5) (4 6) (4 7) (4 8))
"
  ))
(<p> "This \"shearing\" operation cannot be achieved by combining the procedures "(<code>'array-extract)", "(<code>'array-translate)", "(<code>'array-permute)", "(<code>'array-translate)", "(<code>'array-curry)", "(<code>'array-reverse)", and "(<code>'array-sample)".")

(format-lambda-list '(array-copy array
                                 #\[ result-storage-class "generic-storage-class" #\]
                                 #\[ new-domain #f #\]
                                 #\[ mutable? "(specialized-array-default-mutable?)" #\]
                                 #\[ safe? "(specialized-array-default-safe?)" #\]))
(<p> "Assumes that "
     (<code>(<var> 'array))" is an array, "
     (<code>(<var> 'result-storage-class))" is a storage class that can manipulate all the elements of "(<code>(<var> 'array))", "
     (<code>(<var> 'new-domain))" is either "(<code>'#f)" or an interval with the same volume as "(<code>"(array-domain "(<var>'array)")")", and "
     (<code>(<var> 'mutable?))" and "(<code>(<var>'safe?))" are booleans.")
(<p> "If "(<code>(<var> 'new-domain))" is "(<code>'#f)", then it is set to "(<code>"(array-domain "(<var>'array)")")". ")
(<p> "The specialized array returned by "(<code> 'array-copy)" can be defined conceptually by:")
(<pre>
 (<code>"
(list->array (array->list array)
             new-domain
             result-storage-class
             mutable?
             safe?)
"))
(<p> "It is an error if the arguments do not satisfy these conditions.")
(<p>(<b> "Note: ")"If "(<code>(<var> 'new-domain))" is not the same as "(<code>"(array-domain "(<var>'array)")")", one can think of the resulting array as a "(<i>'reshaped)" version of "(<code>(<var> 'array))".")


(format-lambda-list '(array-curry array inner-dimension))
(<p> "If "
     (<code>(<var> 'array))
     " is an array whose domain is an interval  $[l_0,u_0)\\times\\cdots\\times[l_{d-1},u_{d-1})$, and "
     (<code>(<var> 'inner-dimension))
     " is an exact integer strictly between $0$ and $d$, then "(<code>'array-curry)" returns an immutable array with domain "
     "$[l_0,u_0)\\times\\cdots\\times[l_{d-\\text{inner-dimension}-1},u_{d-\\text{inner-dimension}-1})$"
     ", each of whose entries is in itself an array with domain $[l_{d-\\text{inner-dimension}},u_{d-\\text{inner-dimension}})\\times\\cdots\\times[l_{d-1},u_{d-1})$.")
(<p> "For example, if "(<code>'A)" and "(<code> 'B)" are defined by ")
(<pre>
 (<code>"
(define interval (make-interval '#(10 10 10 10)))
(define A (make-array interval list))
(define B (array-curry A 1))

(define A_ (array-getter A))
(define B_ (array-getter B))
  "))
(<p> "so")
(<pre>
 (<code>"
(A_ i j k l) => (list i j k l)"))
(<p> "then "(<code>'B)" is an immutable array with domain "(<code>"(make-interval '#(10 10 10))")", each
of whose elements is itself an (immutable) array and ")
(<pre>
 (<code>"
(equal?
 (A_ i j k l)
 ((array-getter (B_ i j k)) l)) => #t
"))
(<p> "for all multi-indices "(<code> "i j k l")" in "(<code> 'interval)".")
(<p> "The subarrays are immutable, mutable, or specialized according to whether the array argument is immutable, mutable, or specialized.")
(<p> "More precisely, if ")
(<pre>
 (<code> "0 < "(<var> 'inner-dimension)" < (interval-dimension (array-domain "(<var> 'array)"))"))
(<p> "then "(<code> 'array-curry)" returns a result as follows.")
(<p> "If the input array is specialized, then array-curry returns")
(<pre>
 (<code>"
(call-with-values
    (lambda () (interval-projections (array-domain "(<var> 'array)")
                                     "(<var> 'inner-dimension)"))
  (lambda (outer-interval inner-interval)
    (make-array
     outer-interval
     (lambda outer-multi-index
       (specialized-array-share
        "(<var> 'array)"
        inner-interval
        (lambda inner-multi-index
          (apply values
                 (append outer-multi-index
                         inner-multi-index))))))))"))

(<p> "Otherwise, if the input array is mutable, then array-curry returns")
(<pre>
 (<code>"
(call-with-values
    (lambda () (interval-projections (array-domain "(<var> 'array)")
                                     "(<var> 'inner-dimension)"))
  (lambda (outer-interval inner-interval)
    (make-array
     outer-interval
     (lambda outer-multi-index
       (make-array
        inner-interval
        (lambda inner-multi-index
          (apply (array-getter "(<var> 'array)")
                 (append outer-multi-index
                         inner-multi-index)))
        (lambda (v . inner-multi-index)
          (apply (array-setter "(<var> 'array)")
                 v
                 (append outer-multi-index
                         inner-multi-index))))))))"))
(<p> "Otherwise, array-curry returns")
(<pre>
 (<code>"
(call-with-values
    (lambda () (interval-projections (array-domain "(<var> 'array)")
                                     "(<var> 'inner-dimension)"))
  (lambda (outer-interval inner-interval)
    (make-array
     outer-interval
     (lambda outer-multi-index
       (make-array
        inner-interval
        (lambda inner-multi-index
          (apply (array-getter "(<var> 'array)")
                 (append outer-multi-index
                         inner-multi-index))))))))"))
(<p> "It is an error to call "(<code> 'array-curry)" if its arguments do not satisfy these conditions.")
(<p> "If "(<code>(<var>'array))" is a specialized array, the subarrays of the result inherit their safety and mutability from "(<code>(<var>'array))".")
(<p> (<b> "Note: ")"Let's denote by "(<code>(<var>'B))" the result of "(<code>"(array-curry "(<var>'A)" "(<var>'k)")")". While the result of calling "(<code>"(array-getter "(<var>'B)")")
     " is an immutable, mutable, or specialized array according to whether "(<code>(<var>'A))" itself is immutable, mutable, or specialized, "(<code>(<var>'B))" is always an immutable array, where "(<code>"(array-getter "(<var>'B)")")", which returns an array, is computed anew for each call.  If "(<code>"(array-getter "(<var>'B)")")" will be called multiple times with the same arguments, it may be useful to store these results in a specialized array for fast repeated access.")
(<p> "Please see the note in the discussion of "(<a> href: "#array-tile" "array-tile")".")

(<p>"Example:")
(<pre>
 (<code>"
(define a (make-array (make-interval '#(10 10))
                      list))
(define a_ (array-getter a))
(a_ 3 4)  => (3 4)
(define curried-a (array-curry a 1))
(define curried-a_ (array-getter curried-a))
((array-getter (curried-a_ 3)) 4)
                    => (3 4)"))



(format-lambda-list '(array-extract array new-domain))
(<p> "Returns a new array with the same getter (and setter, if appropriate) of the first argument, defined on the second argument.")
(<p> "Assumes that "(<code>(<var> 'array))" is an array and "(<code>(<var> 'new-domain))" is an interval that is a sub-interval of "(<code> "(array-domain "(<var> 'array)")")".  If "(<code>(<var>'array))" is a specialized array, then returns ")
(<pre>
 (<code>"
  (specialized-array-share "(<var> 'array)"
                           "(<var> 'new-domain)"
                           values)
  "))
(<p> "Otherwise, if "(<code>(<var>'array))" is a mutable array, then "(<code> 'array-extract)" returns ")
(<pre>
 (<code>"
  (make-array "(<var> 'new-domain)"
              (array-getter "(<var> 'array)")
              (array-setter "(<var> 'array)"))

" ))
(<p> "Finally, if "(<code>(<var>'array))" is an immutable array, then "(<code> 'array-extract)" returns ")
(<pre>
 (<code>"
  (make-array "(<var> 'new-domain)"
              (array-getter "(<var> 'array)"))
"
              ))
(<p> "It is an error if the arguments of "(<code>'array-extract)" do not satisfy these conditions.")
(<p> "If "(<code>(<var>'array))" is a specialized array, the resulting array inherits its mutability and safety from "(<code>(<var>'array))".")

(format-lambda-list '(array-tile A S))

(<p> "Assume that "(<code>(<var>'A))" is an array and "(<code>(<var>'S))" is a vector of positive, exact integers.  The routine "(<code>'array-tile)" returns a new immutable array $T$, each entry of which is a subarray of "(<code>'A)" whose domain has sidelengths given (mostly) by the entries of "(<code>(<var>'S))".  These subarrays completely \"tile\" "(<code>(<var>'A))", in the sense that every entry in "(<code>(<var>'A))" is an entry of precisely one entry of the result $T$.")
(<p> "More formally, if "(<code>(<var>'S))" is the vector $(s_0,\\ldots,s_{d-1})$, and the domain of "(<code>(<var>'A))" is the interval $[l_0,u_0)\\times\\cdots\\times [l_{d-1},u_{d-1})$, then $T$ is an immutable array with all lower bounds zero and upper bounds given by
$$
\\operatorname{ceiling}((u_0-l_0)/s_0),\\ldots,\\operatorname{ceiling}((u_{d-1}-l_{d-1})/s_{d-1}).
$$
The $i_0,\\ldots,i_{d-1}$ entry of $T$ is "(<code>"(array-extract "(<var>'A)" D_i)")" with the interval "(<code>'D_i)" given by
$$
[l_0+i_0*s_0,\\min(l_0+(i_0+1)s_0,u_0))\\times\\cdots\\times[l_{d-1}+i_{d-1}*s_{d-1},\\min(l_{d-1}+(i_{d-1}+1)s_{d-1},u_{d-1})).
$$
(The \"minimum\" operators are necessary if $u_j-l_j$ is not divisible by $s_j$.) Thus, each entry of $T$ will be a specialized, mutable, or immutable array, depending on the type of the input array "(<code>(<var>'A))".")
(<p> "It is an error if the arguments of "(<code>'array-tile)" do not satisfy these conditions.")
(<p> "If "(<code>(<var>'A))" is a specialized array, the subarrays of the result inherit safety and mutability from "(<code>(<var>'A))".")

(<p> (<b> "Note: ")"The routines "(<code>'array-tile)" and "(<code>'array-curry)" both decompose an array into subarrays, but in different ways.  For example, if "(<code>(<var>'A))" is defined as "(<code>"(make-array (make-interval '#(10 10)) list)")", then "(<code>"(array-tile "(<var>'A)" '#(1 10))")" returns an array with domain "(<code>"(make-interval '#(10 1))")" for which the value at the multi-index "(<code>"("(<var>'i)" 0)")" is an array with domain "(<code>"(make-interval (vector "(<var>'i)" 0) (vector (+ "(<var>'i)" 1) 10))")" (i.e., a two-dimensional array whose elements are two-dimensional arrays), while "(<code>"(array-curry "(<var>'A)" 1)")" returns an array with domain "(<code>"(make-interval '#(10))")", each element of which has domain "(<code>"(make-interval '#(10))")" (i.e., a one-dimensional array whose elements are one-dimensional arrays).")


(format-lambda-list '(array-translate array translation))
(<p> "Assumes that "(<code>(<var>'array))" is a valid array, "(<code>(<var>'translation))" is a valid translation, and that the dimensions of the array and the translation are the same. The resulting array will have domain "(<code>"(interval-translate (array-domain array) translation)")".")
(<p> "If "(<code>(<var>'array))" is a specialized array, returns a new specialized array")
(<pre>
 (<code>"
(specialized-array-share
 "(<var>'array)"
 (interval-translate (array-domain "(<var>'array)")
                     "(<var>'translation)")
 (lambda multi-index
   (apply values
          (map -
               multi-index
               (vector->list "(<var>'translation)")))))
"))
(<p> "that shares the body of "(<code>(<var>'array))", as well as inheriting its safety and mutability.")
(<p> "If "(<code>(<var>'array))" is not a specialized array but is a mutable array, returns a new mutable array")
(<pre>
 (<code>"
(make-array
 (interval-translate (array-domain "(<var>'array)")
                     "(<var>'translation)")
 (lambda multi-index
   (apply (array-getter "(<var>'array)")
          (map -
               multi-index
               (vector->list "(<var>'translation)"))))
 (lambda (val . multi-index)
   (apply (array-setter "(<var>'array)")
          val
          (map -
               multi-index
               (vector->list "(<var>'translation)")))))
 "))
(<p> "that employs the same getter and setter as the original array argument.")
(<p> "If "(<code>(<var>'array))" is not a mutable array, returns a new array")
(<pre>
 (<code>"
(make-array
 (interval-translate (array-domain "(<var>'array)")
                     "(<var>'translation)")
 (lambda multi-index
   (apply (array-getter "(<var>'array)")
          (map - multi-index (vector->list "(<var>'translation)")))))
"))
(<p> "that employs the same getter as the original array.")
(<p> "It is an error if the arguments do not satisfy these conditions.")

(format-lambda-list '(array-permute array permutation))
(<p> "Assumes that "(<code>(<var>'array))" is a valid array, "(<code>(<var>'permutation))" is a valid permutation, and that the dimensions of the array and the permutation are the same. The resulting array will have domain "(<code>"(interval-permute (array-domain array) permutation)")".")
(<p> "We begin with an example.  Assume that the domain of "(<code>(<var>'array))" is represented by the interval  $[0,4)\\times[0,8)\\times[0,21)\\times [0,16)$, as in the example for "(<code>'interval-permute)", and the permutation is "(<code>'#(3 0 1 2))".  Then the domain of the new array is the interval $[0,16)\\times [0,4)\\times[0,8)\\times[0,21)$.")
(<p> "So the multi-index argument of the "(<code>'getter)" of the result of "(<code>'array-permute)" must lie in the new domain of the array, the interval  $[0,16)\\times [0,4)\\times[0,8)\\times[0,21)$.  So if we define "(<code>(<var>'old-getter))" as "(<code>"(array-getter "(<var>'array)")")", the definition of the new array must be in fact")
(<pre>
 (<code>"
(make-array (interval-permute (array-domain "(<var>'array)")
                              '#(3 0 1 2))
            (lambda (l i j k)
              (old-getter i j k l)))
" ))
(<p> "So you see that if the first argument if the new getter is in $[0,16)$, then indeed the fourth argument of "(<code>(<var>'old-getter))" is also in $[0,16)$, as it should be. This is a subtlety that I don't see how to overcome.  It is the listing of the arguments of the new getter, the "(<code>'lambda)", that must be permuted.")

(<p> "Mathematically, we can define $\\pi^{-1}$, the inverse of a permutation $\\pi$, such that $\\pi^{-1}$ composed with $\\pi$ gives the identity permutation.  Then the getter of the new array is, in pseudo-code, "(<code>"(lambda multi-index (apply "(<var>'old-getter)" (")"$\\pi^{-1}$"(<code>" multi-index)))")".  We have assumed that $\\pi^{-1}$ takes a list as an argument and returns a list as a result.")


(<p> "Employing this same pseudo-code, if "(<code>(<var>'array))" is a specialized array and we denote the permutation by $\\pi$, then "(<code>'array-permute)" returns the new specialized array")
(<pre>(<code>"
(specialized-array-share "(<var>'array)"
                         (interval-permute (array-domain "(<var>'array)") "(<unprotected>"&pi;")")
                         (lambda multi-index
                           (apply values ("(<unprotected> "&pi;")(<sup>"-1")" multi-index))))"))
(<p> "The resulting array shares the body of "(<code>(<var>'array))", as well as its safety and mutability.")


(<p> "Again employing this same pseudo-code, if "(<code>(<var>'array))" is not a specialized array, but is
a mutable-array, then "(<code>'array-permute)" returns the new mutable")
(<pre>(<code>"
(make-array (interval-permute (array-domain "(<var>'array)") "(<unprotected>"&pi;")")
            (lambda multi-index
              (apply (array-getter "(<var>'array)")
                     ("(<unprotected> "&pi;")(<sup>"-1")" multi-index)))
            (lambda (val . multi-index)
              (apply (array-setter "(<var>'array)")
                     val
                     ("(<unprotected> "&pi;")(<sup>"-1")" multi-index))))"))
(<p> "which employs the setter and the getter of the argument to "(<code>'array-permute)".")

(<p> "Finally, if "(<code>(<var>'array))" is not a mutable array, then "(<code>'array-permute)" returns")
(<pre>(<code>"
(make-array (interval-permute (array-domain "(<var>'array)") "(<unprotected>"&pi;")")
            (lambda multi-index
              (apply (array-getter "(<var>'array)")
                     ("(<unprotected> "&pi;")(<sup>"-1")" multi-index))))"))
(<p>"It is an error to call "(<code>'array-permute)" if its arguments do not satisfy these conditions.")

(format-lambda-list '(array-rotate array dim))
(<p> "Informally, "(<code> "(array-rotate "(<var>'array)" "(<var>'dim)")")" rotates the axes of "(<code>(<var>'array))" "(<code>(<var>'dim))" places to the left.")
(<p> "More precisely, "(<code> "(array-rotate "(<var>'array)" "(<var> 'dim)")")" assumes that "(<code>(<var>'array))" is an array and "(<code>(<var>'dim))" is an exact integer between 0 (inclusive) and "(<code> "(array-dimension "(<var>'array)")")" (exclusive).  It computes the permutation "(<code>"(vector "(<var>'dim)" ... (- (array-dimension "(<var>'array)") 1) 0 ... (- "(<var>'dim)" 1))")" (unless "(<code>(<var>'dim))" is zero, in which case it constructs the identity permutation) and returns "(<code>"(array-permute "(<var>'array)" "(<var>'permutation)")")". It is an error if the arguments do not satisfy these conditions.")

(format-lambda-list '(array-reverse array #!optional flip?))
(<p> "We assume that "(<code>(<var>'array))" is an array and "(<code>(<var>'flip?))", if given, is a vector of booleans whose length is the same as the dimension of "(<code>(<var>'array))".  If "(<code>(<var>'flip?))" is not given, it is set to a vector with length the same as the dimension of "(<code>(<var>'array))", all of whose elements are "(<code> "#t")".")
(<p> (<code>'array-reverse)" returns a new array  that is specialized,  mutable, or immutable according to whether "(<code>(<var>'array))" is specialized, mutable, or immutable, respectively.  Informally, if "(<code>"(vector-ref "(<var>'flip?)" k)")" is true, then the ordering of multi-indices in the k'th coordinate direction is reversed, and is left undisturbed otherwise.")
(<p> "More formally, we introduce the function ")
(<pre>
 (<code>"
(define flip-multi-index
  (let* ((domain (array-domain "(<code>(<var>'array))"))
         (lowers (interval-lower-bounds->list domain))
         (uppers (interval-upper-bounds->list domain)))
    (lambda (multi-index)
      (map (lambda (i_k flip?_k l_k u_k)
             (if flip?_k
                 (- (+ l_k u_k -1) i_k)
                 i_k))
           multi-index
           (vector->list "(<var>'flip?)")
           lowers
           uppers))))"))
(<p> "Then if "(<code>(<var>'array))" is specialized, "(<code>'array-reverse)" returns ")
(<pre>
 (<code>"
(specialized-array-share
 "(<code>(<var>'array))"
 domain
 (lambda multi-index
   (apply values
          (flip-multi-index multi-index))))"))
(<p> "and the result inherits the safety and mutability of "(<code>(<var>'array))".")
(<p> "Otherwise, if "(<code>(<var>'array))" is mutable, then "(<code>'array-reverse)" returns")
(<pre>
 (<code>"
(make-array
 domain
 (lambda multi-index
   (apply (array-getter "(<code>(<var>'array))")
          (flip-multi-index multi-index)))
   (lambda (v . multi-index)
     (apply (array-setter "(<code>(<var>'array))")
            v
            (flip-multi-index multi-index)))))"))
(<p> "Finally, if "(<code>(<var>'array))" is immutable, then "(<code>'array-reverse)" returns ")
(<pre>
 (<code>"
(make-array
 domain
 (lambda multi-index
   (apply (array-getter "(<code>(<var>'array))")
          (flip-multi-index multi-index))))) "))
(<p> "It is an error if "(<code>(<var>'array))" and "(<code>(<var>'flip?))" don't satisfy these requirements.")
(<p> "The following example using "(<code>'array-reverse)" was motivated by "(<a> href: "https://funcall.blogspot.com/2020/01/palindromes-redux-and-sufficiently.html" "a blog post by Joe Marshall")".")
(<pre>
 (<code>"
(define (palindrome? s)
  (let ((n (string-length s)))
    (or (< n 2)
        (let* ((a
                ;; an array accessing the characters of s
                (make-array (make-interval (vector n))
                            (lambda (i)
                              (string-ref s i))))
               (ra
                ;; the array accessed in reverse order
                (array-reverse a))
               (half-domain
                (make-interval (vector (quotient n 2)))))
          (array-every
           char=?
           ;; the first half of s
           (array-extract a half-domain)
           ;; the reversed second half of s
           (array-extract ra half-domain))))))

(palindrome? \"\") => #t
(palindrome? \"a\") => #t
(palindrome? \"aa\") => #t
(palindrome? \"ab\") => #f
(palindrome? \"aba\") => #t
(palindrome? \"abc\") => #f
(palindrome? \"abba\") => #t
(palindrome? \"abca\") => #f
(palindrome? \"abbc\") => #f
"))


(format-lambda-list '(array-sample array scales))
(<p> "We assume that "(<code>(<var>'array))" is an array all of whose lower bounds are zero, "
     "and "(<code>(<var>'scales))" is a vector of positive exact integers whose length is the same as the dimension of "(<code>(<var>'array))".")
(<p>"Informally, if we construct a new matrix $S$ with the entries of "(<code>(<var>'scales))" on the main diagonal, then "
     "the $\\vec i$th element of "(<code>"(array-sample "(<var>'array)" "(<var>'scales)")")" is the $S\\vec i$th element of "(<code>(<var>'array))".")
(<p> "More formally, if "(<code>(<var>'array))" is specialized, then "(<code>'array-sample)" returns ")
(<pre>
 (<code>"
(specialized-array-share
 "(<code>(<var>'array))"
 (interval-scale (array-domain "(<code>(<var>'array))")
                 "(<code>(<var>'scales))")
 (lambda multi-index
   (apply values
          (map * multi-index (vector->list "(<code>(<var>'scales))")))))"))
(<p> "with the result inheriting the safety and mutability of "(<code>(<var>'array))".")



(<p> "Otherwise, if "(<code>(<var>'array))" is mutable, then "(<code>'array-sample)" returns")
(<pre>
 (<code>"
(make-array
 (interval-scale (array-domain "(<code>(<var>'array))")
                 "(<code>(<var>'scales))")
 (lambda multi-index
   (apply (array-getter "(<code>(<var>'array))")
          (map * multi-index (vector->list "(<code>(<var>'scales))"))))
 (lambda (v . multi-index)
   (apply (array-setter "(<code>(<var>'array))")
          v
          (map * multi-index (vector->list "(<code>(<var>'scales))")))))"))
(<p> "Finally, if "(<code>(<var>'array))" is immutable, then "(<code>'array-sample)" returns ")
(<pre>
 (<code>"
(make-array
 (interval-scale (array-domain "(<code>(<var>'array))")
                 "(<code>(<var>'scales))")
 (lambda multi-index
   (apply (array-getter "(<code>(<var>'array))")
          (map * multi-index (vector->list "(<code>(<var>'scales))")))))"))
(<p> "It is an error if "(<code>(<var>'array))" and "(<code>(<var>'scales))" don't satisfy these requirements.")

(format-lambda-list '(array-outer-product op array1 array2))
(<p> "Implements the outer product of "(<code>(<var>'array1))" and "(<code>(<var>'array2))" with the operator "(<code>(<var>'op))", similar to the APL function with the same name.")
(<p> "Assume that "(<code>(<var>'array1))" and "(<code>(<var>'array2))" are arrays and that "(<code>(<var>'op))" is a function of two arguments. Assume that "
     (<code>"(list-tail l n)")" returns the list remaining after the first "(<code>(<var>'n))" items of the list "(<code>(<var>'l))" have been removed, and "
     (<code>"(list-take l n)")" returns a new list consisting of the first "(<code>(<var>'n))" items of the list "(<code>(<var>'l))". Then "(<code>(<var>'array-outer-product))" returns the immutable array")
(<pre>(<code>"
(make-array (interval-cartesian-product (array-domain array1)
                                        (array-domain array2))
            (lambda args
              (op (apply (array-getter array1) (list-take args (array-dimension array1)))
                  (apply (array-getter array2) (list-tail args (array-dimension array1))))))"))
(<p> "This operation can be considered a partial inverse to "(<code>'array-curry)".  It is an error if the arguments do not satisfy these assumptions.")
(<p> (<b> "Note: ")"You can see from the above definition that if "(<code>(<var>'C))" is "(<code>"(array-outer-product "(<var>'op)" "(<var>'A)" "(<var>'B)")")", then each call to "(<code>"(array-getter "(<var>'C)")")
     " will call "(<code>(<var>'op))" as well as "(<code>"(array-getter "(<var>'A)")")" and "(<code>"(array-getter "(<var>'B)")")".  This implies that if all elements of "(<code>(<var>'C))" are eventually accessed, then "
     (<code>"(array-getter "(<var>'A)")")" will be called "(<code>"(array-volume "(<var>'B)")")" times; similarly "(<code>"(array-getter "(<var>'B)")")" will be called "(<code>"(array-volume "(<var>'A)")")" times. ")
(<p> "This implies that if "(<code>"(array-getter "(<var>'A)")")" is expensive to compute (for example, if it's returning an array, as does "(<code>'array-curry)") then the elements of "(<code>(<var>'A))
     " should be pre-computed if necessary and stored in a specialized array, typically using "(<code>'array-copy)", before that specialized array is passed as an argument to "(<code>'array-outer-product)".  In the examples below, "
     "the code for Gaussian elimination applies "(<code>'array-outer-product)" to shared specialized arrays, which are of course themselves specialized arrays; the code for matrix multiplication and "(<code>'inner-product)
     " applies "(<code>'array-outer-product)" to curried arrays, so we apply "(<code>"array-copy")" to the arguments before passage to "(<code>'array-outer-product)".")

(format-lambda-list '(array-map f array #\. arrays))
(<p> "If "(<code>(<var> 'array))", "(<code>"(car "(<var> 'arrays)")")", ... all have the same domain and "(<code>(<var> 'f))" is a procedure, then "(<code> 'array-map)"
returns a new immutable array with the same domain and getter")
(<pre>
 (<code>"
(lambda multi-index
  (apply "(<var>'f)"
         (map (lambda (g)
                (apply g multi-index))
              (map array-getter
                   (cons "(<var> 'array)" "(<var> 'arrays)")))))"))
(<p> "It is assumed that "(<code>(<var> 'f))" is appropriately defined to be evaluated in this context.")

(<p> "It is expected that "(<code> 'array-map)" and "(<code> 'array-for-each)" will specialize the construction of")
(<pre>
 (<code>"
(lambda multi-index
  (apply "(<var>'f)"
         (map (lambda (g)
                (apply g multi-index))
              (map array-getter
                   (cons "(<var> 'array)"
                         "(<var> 'arrays)")))))"))
(<p> "It is an error to call "(<code> 'array-map)" if its arguments do not satisfy these conditions.")

(<p> (<b> "Note: ")"The ease of constructing temporary arrays without allocating storage makes it trivial to imitate, e.g., Javascript's map with index. For example, we can add the index to each element of an array "(<code>(<var>'a))" by ")
(<pre>
 (<code>"
(array-map +
           a
           (make-array (array-domain a)
                       (lambda (i) i)))"))
(<p> "or even")
(<pre>
 (<code>"
(make-array (array-domain a)
            (let ((a_ (array-getter a)))
              (lambda (i)
                (+ (a_ i) i))))"
))


(format-lambda-list '(array-for-each f array #\. arrays))
(<p> "If "(<code>(<var> 'array))", "(<code>"(car "(<var> 'arrays)")")", ... all have the same domain  and "(<code>(<var> 'f))" is an appropriate procedure, then "(<code> 'array-for-each)"
calls")
(<pre>
 (<code>"
(interval-for-each
 (lambda multi-index
   (apply "(<var>'f)"
          (map (lambda (g)
                 (apply g multi-index))
               (map array-getter
                    (cons "(<var> 'array)"
                          "(<var> 'arrays)")))))
 (array-domain "(<var> 'array)"))"))
(<p> "In particular, "(<code> 'array-for-each)" always walks the indices of the arrays in lexicographical order.")

(<p> "It is expected that "(<code> 'array-map)" and "(<code> 'array-for-each)" will specialize the construction of")
(<pre>
 (<code>"
(lambda multi-index
  (apply "(<var>'f)"
         (map (lambda (g)
                (apply g multi-index))
              (map array-getter
                   (cons "(<var> 'array)"
                         "(<var> 'arrays)")))))"))
(<p> "It is an error to call "(<code> 'array-for-each)" if its arguments do not satisfy these conditions.")

(format-lambda-list '(array-fold kons knil array))
(<p> "If we use the defining relations for fold over lists from "(<a> href: "https://srfi.schemers.org/srfi-1/" "SRFI 1")":")
(<pre>
 (<code>"
(fold kons knil lis)
    = (fold kons (kons (car lis) knil) (cdr lis))
(fold kons knil '())
    = knil
 "))
(<p> "then "(<code>"(array-fold "(<var>'kons)" " (<var>'knil)" "(<var> 'array)")")" returns ")
(<pre>
 (<code>"
(fold "(<var>'kons)" " (<var>'knil)" (array->list "(<var> 'array)"))"))
(<p> "It is an error if "(<code>(<var>'array))" is not an array, or if "(<code>(<var>'kons))" is not a procedure.")

(format-lambda-list '(array-fold-right kons knil array))
(<p> "If we use the defining relations for fold-right over lists from "(<a> href: "https://srfi.schemers.org/srfi-1/" "SRFI 1")":")
(<pre>
 (<code>"
(fold-right kons knil lis)
    = (kons (car lis) (fold-right kons knil (cdr lis)))
(fold-right kons knil '())
    = knil
"))
(<p> "then "(<code>"(array-fold-right "(<var>'kons)" " (<var>'knil)" "(<var> 'array)")")" returns ")
(<pre>
 (<code>"
(fold-right "(<var>'kons)" " (<var>'knil)" (array->list "(<var> 'array)"))"))
(<p> "It is an error if "(<code>(<var>'array))" is not an array, or if "(<code>(<var>'kons))" is not a procedure.")

(format-lambda-list '(array-reduce op A))

(<p> "We assume that "(<code>(<var>'A))" is an array and "(<code>(<var>'op))" is a procedure of two arguments that is associative, i.e., "(<code>"("(<var>'op)" ("(<var>'op)" "(<var>'x)" "(<var>'y)") "(<var>'z)")")" is the same as "(<code>"("(<var>'op)" "(<var>'x)" ("(<var>'op)"  "(<var>'y)" "(<var>'z)"))")".")
(<p> "Then "(<code>"(array-reduce "(<var>'op)" "(<var>'A)")")" returns")
(<pre>
 (<code>"
(let ((box '())
      (A_ (array-getter A)))
  (interval-for-each
   (lambda args
     (if (null? box)
         (set! box (list (apply A_ args)))
         (set-car! box (op (car box)
                           (apply A_ args)))))
   (array-domain A))
  (car box))
"))
(<p> "The implementation is allowed to use the associativity of "(<code>(<var>'op))" to reorder the computations in "(<code>'array-reduce)". It is an error if the arguments do not satisfy these conditions.")
(<p> "As an example, we consider the finite sum:
$$
S_m=\\sum_{k=1}^m \\frac 1{k^2}.
$$
One can show that
$$
\\frac 1 {m+1}<\\frac{\\pi^2}6-S_m<\\frac 1m.
$$
We attempt to compute this in floating-point arithmetic in two ways. In the first, we apply "
     (<code>'array-reduce)" to an array containing the terms of the series, basically a serial computation.  In the second, we divide the series into blocks of no more than 1,000 consecutive terms, apply "
     (<code>'array-reduce)" to get a new sequence of terms, and repeat the process. The second way is approximately what might happen with GPU computing.")
(<p> " We find with $m=1{,}000{,}000{,}000$: ")
(<pre>
 (<code>"
(define A (make-array (make-interval '#(1) '#(1000000001))
                      (lambda (k)
                        (fl/ (flsquare (inexact k))))))
(define (block-sum A)
  (let ((N (interval-volume (array-domain A))))
    (cond ((<= N 1000)
           (array-reduce fl+ A))
          ((<= N (square 1000))
           (block-sum (array-map block-sum
                                 (array-tile A (vector (integer-sqrt N))))))
          (else
           (block-sum (array-map block-sum
                                 (array-tile A (vector (quotient N 1000)))))))))
(array-reduce fl+ A) => 1.644934057834575
(block-sum A)        => 1.6449340658482325
"))
(<p> "Since $\\pi^2/6\\approx{}$"(<code>"1.6449340668482264")", we see  using the first method that the difference $\\pi^2/6-{}$"(<code>"1.644934057834575")"${}\\approx{}$"(<code>"9.013651380840315e-9")" and with the second we have "
     "$\\pi^2/6-{}$"(<code>"1.6449340658482325")"${}\\approx{}$"(<code>"9.99993865491433e-10")".  The true difference should be between $\\frac 1{1{,}000{,}000{,}001}\\approx{}$"(<code>"9.99999999e-10")" and $\\frac 1{1{,}000{,}000{,}000}={}$"(<code>"1e-9")". The difference for the first method is about 10 times too big, and, in fact, will not change further because any further terms, when added to the partial sum, are too small to increase the sum after rounding-to-nearest in double-precision IEEE-754 floating-point arithmetic.")


(format-lambda-list '(array-any pred array1 array2 "..."))

(<p> "Assumes that "(<code>(<var>'array1))", "(<code>(<var>'array2))", etc., are arrays, all with the same domain, which we'll call "(<code>'interval)".  Also assumes that "(<code>(<var>'pred))" is a procedure that takes as many arguments as there are arrays and returns a single value.")
(<p> (<code>'array-any)" first applies "(<code>"(array-getter "(<var>'array1)")")", etc., to the first element of "(<code>'interval)" in lexicographical order, to which value it then applies "(<code>(<var>'pred))".")
(<p> "If the result of "(<code>(<var>'pred))" is not "(<code>'#f)", then that result is returned by "(<code>'array-any)".  If the result of "(<code>(<var>'pred))" is "(<code>'#f)", then "(<code>'array-any)" continues with the second element of "(<code>'interval)", etc., returning the first nonfalse value of  "(<code>(<var>'pred))".")
(<p> "If "(<code>(<var>'pred))" always returns  "(<code>'#f)", then "(<code>'array-any)" returns "(<code>'#f)".")
(<p> "If it happens that "(<code>(<var>'pred))" is applied to the results of applying "(<code>"(array-getter "(<var>'array1)")")", etc., to the last element of "(<code>'interval)", then this last call to "(<code>(<var>'pred))" is in tail position.")
(<p> "The functions "(<code>"(array-getter "(<var>'array1)")")", etc., are applied only to those values of "(<code>'interval)" necessary to determine the result of "(<code>'array-any)".")
(<p> "It is an error if the arguments do not satisfy these assumptions.")

(format-lambda-list '(array-every pred array1 array2 "..."))

(<p> "Assumes that "(<code>(<var>'array1))", "(<code>(<var>'array2))", etc., are arrays, all with the same domain, which we'll call "(<code>'interval)".  Also assumes that "(<code>(<var>'pred))" is a procedure that takes as many arguments as there are arrays and returns a single value.")
(<p> (<code>'array-every)" first applies "(<code>"(array-getter "(<var>'array1)")")", etc., to the first element of "(<code>'interval)" in lexicographical order, to which values it then applies "(<code>(<var>'pred))".")
(<p> "If the result of "(<code>(<var>'pred))" is "(<code>'#f)", then that result is returned by "(<code>'array-every)".  If the result of "(<code>(<var>'pred))" is nonfalse, then "(<code>'array-every)" continues with the second element of "(<code>'interval)", etc., returning the first  value of  "(<code>(<var>'pred))" that is "(<code>'#f)".")
(<p> "If "(<code>(<var>'pred))" always returns  a nonfalse value, then the last nonfalse value returned by "(<code>(<var>'pred))" is also returned by "(<code>'array-every)".")
(<p> "If it happens that "(<code>(<var>'pred))" is applied to the results of applying "(<code>"(array-getter "(<var>'array1)")")", etc., to the last element of "(<code>'interval)", then this last call to "(<code>(<var>'pred))" is in tail position.")
(<p> "The functions "(<code>"(array-getter "(<var>'array1)")")", etc., are applied only to those values of "(<code>'interval)" necessary to determine the result of "(<code>'array-every)".")
(<p> "It is an error if the arguments do not satisfy these assumptions.")


(format-lambda-list '(array->list array) 'array-rarrow-list)
(<p> "Stores the elements of "(<code>(<var>'array))" into a newly allocated list in lexicographical order.  It is an error if "(<code>(<var>'array))" is not an array.")
(<p> "It is guaranteed that "(<code>"(array-getter "(<var>'array)")")" is called precisely once for each multi-index in "(<code>"(array-domain "(<var>'array)")")" in lexicographical order.")

(format-lambda-list '(list->array l domain  #\[ result-storage-class "generic-storage-class" #\] #\[ mutable? "(specialized-array-default-mutable?)" #\] #\[ safe? "(specialized-array-default-safe?)" #\]) 'list-rarrow-array)
(<p> "Assumes that "
     (<code>(<var> 'l))" is an list, "
     (<code>(<var> 'domain))" is an interval with volume the same as the length of "(<code>(<var> 'l))",  "
     (<code>(<var> 'result-storage-class))" is a storage class that can manipulate all the elements of "(<code>(<var> 'l))", and "
     (<code>(<var> 'mutable?))" and "(<code>(<var>'safe?))" are booleans.")
(<p> "Returns a specialized array with domain "(<code>(<var>'domain))" whose elements are the elements of the list "(<code>(<var>'l))" stored in lexicographical order.  The result is mutable or safe depending on the values of "
     (<code>(<var> 'mutable?))" and "(<code>(<var>'safe?))".")
(<p> "It is an error if the arguments do not satisfy these assumptions, or if any element of  "(<code>(<var>'l))" cannot be stored in the body of "(<code>(<var>'result-storage-class))", and this last error shall be detected and raised.")

(format-lambda-list '(array-assign! destination source))
(<p> "Assumes that "(<code>(<var>'destination))" is a mutable array and "(<code>(<var>'source))" is an array, and that the elements of "(<code>(<var>'source))" can be stored into "(<code>(<var>'destination))".")
(<p> "The array "(<code>(<var>'destination))" must be compatible with "(<code>(<var>'source))", in the sense that either "(<code>(<var>'destination))" and "(<code>(<var>'source))" have the same domain, or "(<code>(<var>'destination))" is a specialized array whose elements are stored adjacently and in order in its body and whose domain has the same volume as the domain of "(<code>(<var>'source))".")
(<p> "Evaluates "(<code>"(array-getter "(<var>'source)")")" on the multi-indices in "(<code>"(array-domain "(<var>'source)")")" in lexicographical order, "
     "and assigns each value to the multi-index in "(<code>(<var>'destination))" in the same lexicographical order.")
(<p> "It is an error if the arguments don't satisfy these assumptions.")
(<p> "If assigning any element of "(<code>(<var>'destination))" affects the value of any element of "(<code>(<var>'source))", then the result is undefined.")
(<p> (<b>"Note: ")"If the domains of "(<code>(<var>'destination))" and "(<code>(<var>'source))" are not the same, one can think of "(<code>(<var>'destination))" as a "(<i>'reshaped)" copy of "(<code>(<var>'source))".")

(format-lambda-list '(array-ref A i0 #\. i-tail))
(<p> "Assumes that "(<code>(<var>'A))" is an array, and every element of "(<code>"(cons "(<var> "i0 i-tail")")")" is an exact integer.")
(<p> "Returns "(<code>"(apply (array-getter "(<var>'A)") "(<var>"i0 i-tail")")")".")
(<p> "It is an error if "(<code>(<var>'A))" is not an array, or if the number of arguments specified is not the correct number for "(<code>"(array-getter "(<var>'A)")")".")

(format-lambda-list '(array-set! A v i0 #\. i-tail))
(<p> "Assumes that "(<code>(<var>'A))" is a mutable array, that "(<code>(<var>'v))" is a value that can be stored within that array, and that every element of "(<code>"(cons "(<var> "i0 i-tail")")")" is an exact integer.")
(<p> "Returns "(<code>"(apply (array-setter "(<var>'A)") "(<var>"v i0 i-tail")")")".")
(<p> "It is an error if "(<code>(<var>'A))" is not a mutable array, if "(<code>'v)" is not an appropriate value to be stored in that array, or if the number of arguments specified is not the correct number for "(<code>"(array-setter "(<var>'A)")")".")

(<p>(<b> "Note: ")"In the sample implementation, because "(<code>'array-ref)" and "(<code>'array-set!)" take a variable number of arguments and they must check that "(<code>(<var>'A))" is an array of the appropriate type, programs written in a style using these functions, rather than the style in which "(<code>'1D-Haar-loop)" is coded below, can take up to three times as long runtime.")

(<p>(<b> "Note: ")"In the sample implementation, checking whether the multi-indices are exact integers and within the domain of the array, and checking whether the value is appropriate for storage into the array, is delegated to the underlying definition of the array argument.  If the first argument is a safe specialized array, then these items are checked; if it is an unsafe specialized array, they are not.  If it is a generalized array, it is up to the programmer whether to define the getter and setter of the array to check the correctness of the arguments.")

(format-lambda-list '(specialized-array-reshape array new-domain #\[ copy-on-failure? #f #\]))
(<p> "Assumes that "(<code>(<var>'array))" is a specialized array, "(<code>(<var>'new-domain))" is an interval with the same volume as "(<code>"(array-domain "(<var>'array)")")", and "(<code>(<var>'copy-on-failure?))", if given, is a boolean.")
(<p> "If there is an affine map that takes the multi-indices in "(<code>(<var>'new-domain))" to the cells in "(<code>"(array-body "(<var>'array)")")" storing the elements of "(<code>(<var>'array))" in lexicographical order, returns a new specialized array, with the same body and elements as "(<code>(<var>'array))" and domain "(<code>(<var>'new-domain))".  The result inherits its mutability and safety from "(<code>(<var>'array))".")
(<p> "If there is not an affine map that takes the multi-indices in "(<code>(<var>'new-domain))" to the cells storing the elements of "(<code>(<var>'array))" in lexicographical order and "(<code>(<var>'copy-on-failure?))" is "(<code>'#t)", then returns a specialized array copy of "(<code>(<var>'array))" with domain "(<code>(<var>'new-domain))", storage class "(<code>"(array-storage-class "(<var>'array)")")", mutability "(<code>"(mutable-array? "(<var>'array)")")", and safety "(<code>"(array-safe? "(<var>'array)")")".")
(<p> "It is an error if these conditions on the arguments are not met.")
(<p>(<b>"Note: ")"The code in the sample implementation to determine whether there exists an affine map from "(<code>(<var>'new-domain))" to the multi-indices of the elements of "(<code>(<var>'array))" in lexicographical order is modeled on the corresponding code in the Python library NumPy.")
(<p>(<b> "Note: ")"In the sample implementation, if an array cannot be reshaped and "(<code>(<var>'copy-on-failure?))" is "(<code>'#f)", an error is raised in tail position.  An implementation might want to replace this error call with a continuable exception to give the programmer more flexibility.")
(<p>(<b>"Examples: ")"Reshaping an array is not a Bawden-type array transform.  For example, we use "(<code>'array-display)" defined below to see:")
(<pre>
 (<code>"
;;; The entries of A are the multi-indices of the locations

(define A (array-copy (make-array (make-interval '#(3 4)) list)))

(array-display A)

;;; Displays

;;; (0 0)   (0 1)   (0 2)   (0 3)
;;; (1 0)   (1 1)   (1 2)   (1 3)
;;; (2 0)   (2 1)   (2 2)   (2 3)

(array-display (array-rotate A 1))

;;; Displays

;;; (0 0)   (1 0)   (2 0)
;;; (0 1)   (1 1)   (2 1)
;;; (0 2)   (1 2)   (2 2)
;;; (0 3)   (1 3)   (2 3)

(array-display (specialized-array-reshape A (make-interval '#(4 3))))

;;; Displays

;;; (0 0)   (0 1)   (0 2)
;;; (0 3)   (1 0)   (1 1)
;;; (1 2)   (1 3)   (2 0)
;;; (2 1)   (2 2)   (2 3)

(define B (array-sample A '#(2 1)))

(array-display B)

;;; Displays

;;; (0 0)   (0 1)   (0 2)   (0 3)
;;; (2 0)   (2 1)   (2 2)   (2 3)

(array-display (specialized-array-reshape B (make-interval '#(8)))) => fails

(array-display (specialized-array-reshape B (make-interval '#(8)) #t))

;;; Displays

;;; (0 0)   (0 1)   (0 2)   (0 3)   (2 0)   (2 1)   (2 2)   (2 3)
"))
(<p>"The following examples succeed:")
(<pre>
 (<code>"
(specialized-array-reshape
 (array-copy (make-array (make-interval '#(2 1 3 1)) list))
 (make-interval '#(6)))
(specialized-array-reshape
 (array-copy (make-array (make-interval '#(2 1 3 1)) list))
 (make-interval '#(3 2)))
(specialized-array-reshape
 (array-reverse (array-copy (make-array (make-interval '#(2 1 3 1)) list)))
 (make-interval '#(6)))
(specialized-array-reshape
 (array-reverse (array-copy (make-array (make-interval '#(2 1 3 1)) list)))
 (make-interval '#(3 2)))
(specialized-array-reshape
 (array-reverse (array-copy (make-array (make-interval '#(2 1 3 1)) list)) '#(#f #f #f #t))
 (make-interval '#(3 2)))
(specialized-array-reshape
 (array-reverse (array-copy (make-array (make-interval '#(2 1 3 1)) list)) '#(#f #f #f #t))
 (make-interval '#(3 1 2 1)))
(specialized-array-reshape
 (array-sample (array-reverse (array-copy (make-array (make-interval '#(2 1 4 1)) list)) '#(#f #f #f #t)) '#(1 1 2 1))
 (make-interval '#(4)))
(specialized-array-reshape
 (array-sample (array-reverse (array-copy (make-array (make-interval '#(2 1 4 1)) list)) '#(#t #f #t #t)) '#(1 1 2 1))
 (make-interval '#(4)))
"))
(<p>"The following examples raise an exception: ")
(<pre>
 (<code>"
(specialized-array-reshape
 (array-reverse (array-copy (make-array (make-interval '#(2 1 3 1)) list)) '#(#t #f #f #f))
 (make-interval '#(6)))
(specialized-array-reshape
 (array-reverse (array-copy (make-array (make-interval '#(2 1 3 1)) list)) '#(#t #f #f #f))
 (make-interval '#(3 2)))
(specialized-array-reshape
 (array-reverse (array-copy (make-array (make-interval '#(2 1 3 1)) list)) '#(#f #f #t #f))
 (make-interval '#(6)))
(specialized-array-reshape
 (array-reverse (array-copy (make-array (make-interval '#(2 1 3 1)) list)) '#(#f #f #t #t))
 (make-interval '#(3 2)))
(specialized-array-reshape
 (array-sample (array-reverse (array-copy (make-array (make-interval '#(2 1 3 1)) list)) '#(#f #f #f #t)) '#(1 1 2 1))
 (make-interval '#(4)) )
(specialized-array-reshape
 (array-sample (array-reverse (array-copy (make-array (make-interval '#(2 1 4 1)) list)) '#(#f #f #t #t)) '#(1 1 2 1))
 (make-interval '#(4)))
"))
(<p> "In the next examples, we start with vector fields, $100\\times 100$ arrays of 4-vectors.  In one example, we reshape each large array to $100\\times 100\\times2\\times2$ vector fields (so we consider each 4-vector as a $2\\times 2$ matrix), and multiply the $2\\times 2$ matrices together.  In the second example, we reshape each 4-vector to a $2\\times 2$ matrix individually, and compare the times.")
(<pre>
 (<code>"
(define interval-flat (make-interval '#(100 100 4)))

(define interval-2x2  (make-interval '#(100 100 2 2)))

(define A (array-copy (make-array interval-flat (lambda args (random-integer 5)))))

(define B (array-copy (make-array interval-flat (lambda args (random-integer 5)))))

(define C (array-copy (make-array interval-flat (lambda args 0))))

(define (2x2-matrix-multiply-into! A B C)
  (let ((C! (array-setter C))
        (A_ (array-getter A))
        (B_ (array-getter B)))
    (C! (+ (* (A_ 0 0) (B_ 0 0))
           (* (A_ 0 1) (B_ 1 0)))
        0 0)
    (C! (+ (* (A_ 0 0) (B_ 0 1))
           (* (A_ 0 1) (B_ 1 1)))
        0 1)
    (C! (+ (* (A_ 1 0) (B_ 0 0))
           (* (A_ 1 1) (B_ 1 0)))
        1 0)
    (C! (+ (* (A_ 1 0) (B_ 0 1))
           (* (A_ 1 1) (B_ 1 1)))
        1 1)))

;;; Reshape A, B, and C to change all the 4-vectors to 2x2 matrices

(time
 (array-for-each 2x2-matrix-multiply-into!
                 (array-curry (specialized-array-reshape A interval-2x2) 2)
                 (array-curry (specialized-array-reshape B interval-2x2) 2)
                 (array-curry (specialized-array-reshape C interval-2x2) 2)))
;;; Displays

;;;    0.015186 secs real time
;;;    0.015186 secs cpu time (0.015186 user, 0.000000 system)
;;;    4 collections accounting for 0.004735 secs real time (0.004732 user, 0.000000 system)
;;;    46089024 bytes allocated
;;;    no minor faults
;;;    no major faults

;;; Reshape each 4-vector to a 2x2 matrix individually

(time
 (array-for-each (lambda (A B C)
                   (2x2-matrix-multiply-into!
                    (specialized-array-reshape A (make-interval '#(2 2)))
                    (specialized-array-reshape B (make-interval '#(2 2)))
                    (specialized-array-reshape C (make-interval '#(2 2)))))
                 (array-curry A 1)
                 (array-curry B 1)
                 (array-curry C 1)))

;;; Displays

;;;    0.039193 secs real time
;;;    0.039193 secs cpu time (0.039191 user, 0.000002 system)
;;;    6 collections accounting for 0.006855 secs real time (0.006851 user, 0.000001 system)
;;;    71043024 bytes allocated
;;;    no minor faults
;;;    no major faults
"))

(<h2> "Implementation")
(<p> "We provide an implementation in "(<a> href: "https://github.com/gambit/gambit" "Gambit Scheme")"; the nonstandard techniques used
in the implementation are: DSSSL-style optional and keyword arguments; a
unique object to indicate absent arguments; "(<code>"define-structure")";
and "(<code>"define-macro")".")
(<p> "There is a "(<a> href: "https://github.com/scheme-requests-for-implementation/srfi-179"  "git repository")" of this document, a sample implementation, a test file, and other materials.")
(<h2> "Relationship to other SRFIs")
(<p> "Final SRFIs "(<a> href: "#SRFI-25" "25")", "(<a> href: "#SRFI-47" "47")", "(<a> href: "#SRFI-58" "58")", and "(<a> href: "#SRFI-63" "63")" deal with \"Multi-dimensional Array Primitives\", \"Array\", \"Array Notation\",
and \"Homogeneous and Heterogeneous Arrays\", respectively.  Each of these previous SRFIs deal with what we call in this SRFI
specialized arrays.  Many of the functions in these previous SRFIs  have corresponding forms in this SRFI.  For example, from "(<a> href: "https://srfi.schemers.org/srfi-63/" "SRFI 63")", we can
translate: ")
(<dl>
 (<dt> (<code> "(array? obj)"))
 (<dd> (<code> "(array? obj)"))
 (<dt> (<code> "(array-rank A)"))
 (<dd> (<code> "(array-dimension A)"))
 (<dt> (<code> "(make-array prototype k1 ...)"))
 (<dd> (<code> "(make-specialized-array (make-interval (vector k1 ...)) storage-class)")".")
 (<dt> (<code> "(make-shared-array A mapper k1 ...)"))
 (<dd> (<code> "(specialized-array-share A (make-interval (vector k1 ...)) mapper)"))
 (<dt> (<code> "(array-in-bounds? A index1 ...)"))
 (<dd> (<code> "(interval-contains-multi-index? (array-domain A) index1 ...)"))
 (<dt> (<code> "(array-ref A k1 ...)"))
 (<dd> (<code> "(let ((A_ (array-getter A))) ... (A_ k1 ...) ... )")" or "(<code> "(array-ref A k1 ...)"))
 (<dt> (<code> "(array-set! A obj k1 ...)"))
 (<dd> (<code> "(let ((A! (array-setter A))) ... (A! obj k1 ...) ...)")" or "(<code> "(array-set! A obj k1 ...)"))
 )
(<p> "At the same time, this SRFI has some special features:")
(<ul>
 (<li> "Intervals, used as the domains of arrays in this SRFI, are useful
objects in their own rights, with their own procedures.  We make a sharp distinction between the domains
of arrays and the arrays themselves.")
 (<li> "Intervals can have nonzero lower bounds in each dimension.")
 (<li> "Intervals cannot be empty.")
 (<li> "Arrays must have a getter, but may have no setter.")
 (<li> "There are many predefined array transformations: "
       (<code>'array-extract)", "
       (<code>'array-tile)", "
       (<code>'array-translate)", "
       (<code>'array-permute)", "
       (<code>'array-rotate)", "
       (<code>'array-sample)", "
       (<code>'array-reverse)".")
)

(<h2> "Other examples")
(<p> "Image processing applications provided significant motivation for this SRFI.")
(<p> (<b> "Manipulating images in PGM format. ")"On a system with eight-bit chars, one
can write routines to read and write greyscale images in the PGM format of the netpbm package as follows.  The  lexicographical
order in "(<code>'array-copy)" guarantees the the correct order of execution of the input procedures:")

(<pre>
 (<code>"
(define make-pgm   cons)
(define pgm-greys  car)
(define pgm-pixels cdr)

(define (read-pgm file)

  (define (read-pgm-object port)
    (skip-white-space port)
    (let ((o (read port)))
      ;; to skip the newline or next whitespace
      (read-char port)
      (if (eof-object? o)
          (error \"reached end of pgm file\")
          o)))

  (define (skip-to-end-of-line port)
    (let loop ((ch (read-char port)))
      (if (not (eq? ch #\\newline))
          (loop (read-char port)))))

  (define (white-space? ch)
    (case ch
      ((#\\newline #\\space #\\tab) #t)
      (else #f)))

  (define (skip-white-space port)
    (let ((ch (peek-char port)))
      (cond ((white-space? ch)
             (read-char port)
             (skip-white-space port))
            ((eq? ch #\\#)
             (skip-to-end-of-line port)
             (skip-white-space port))
            (else #f))))

  ;; The image file formats defined in netpbm
  ;; are problematical because they read the data
  ;; in the header as variable-length ISO-8859-1 text,
  ;; including arbitrary whitespace and comments,
  ;; and then they may read the rest of the file
  ;; as binary data.
  ;; So we give here a solution of how to deal
  ;; with these subtleties in Gambit Scheme.

  (call-with-input-file
      (list path:          file
            char-encoding: 'ISO-8859-1
            eol-encoding:  'lf)
    (lambda (port)

      ;; We're going to read text for a while,
      ;; then switch to binary.
      ;; So we need to turn off buffering until
      ;; we switch to binary.

      (port-settings-set! port '(buffering: #f))

      (let* ((header (read-pgm-object port))
             (columns (read-pgm-object port))
             (rows (read-pgm-object port))
             (greys (read-pgm-object port)))

        ;; Now we switch back to buffering
        ;; to speed things up.

        (port-settings-set! port '(buffering: #t))

        (make-pgm
         greys
         (array-copy
          (make-array
           (make-interval (vector rows columns))
           (cond ((or (eq? header 'p5)
                      (eq? header 'P5))
                  ;; pgm binary
                  (if (< greys 256)
                      ;; one byte/pixel
                      (lambda (i j)
                        (char->integer
                         (read-char port)))
                      ;; two bytes/pixel,
                      ;;little-endian
                      (lambda (i j)
                        (let* ((first-byte
                                (char->integer
                                 (read-char port)))
                               (second-byte
                                (char->integer
                                 (read-char port))))
                          (+ (* second-byte 256)
                             first-byte)))))
                 ;; pgm ascii
                 ((or (eq? header 'p2)
                      (eq? header 'P2))
                  (lambda (i j)
                      (read port)))
                   (else
                    (error \"not a pgm file\"))))
          (if (< greys 256)
              u8-storage-class
              u16-storage-class)))))))

(define (write-pgm pgm-data file #!optional force-ascii)
  (call-with-output-file
      (list path:          file
            char-encoding: 'ISO-8859-1
            eol-encoding:  'lf)
    (lambda (port)
      (let* ((greys
              (pgm-greys pgm-data))
             (pgm-array
              (pgm-pixels pgm-data))
             (domain
              (array-domain pgm-array))
             (rows
              (fx- (interval-upper-bound domain 0)
                   (interval-lower-bound domain 0)))
             (columns
              (fx- (interval-upper-bound domain 1)
                   (interval-lower-bound domain 1))))
        (if force-ascii
            (display \"P2\" port)
            (display \"P5\" port))
        (newline port)
        (display columns port) (display " " port)
        (display rows port) (newline port)
        (display greys port) (newline port)
        (array-for-each
         (if force-ascii
             (let ((next-pixel-in-line 1))
               (lambda (p)
                 (write p port)
                 (if (fxzero? (fxand next-pixel-in-line 15))
                     (begin
                       (newline port)
                       (set! next-pixel-in-line 1))
                     (begin
                       (display " " port)
                       (set! next-pixel-in-line
                             (fx+ 1 next-pixel-in-line))))))
             (if (fx< greys 256)
                 (lambda (p)
                   (write-u8 p port))
                 (lambda (p)
                   (write-u8 (fxand p 255) port)
                   (write-u8 (fxarithmetic-shift-right p 8)
                             port))))
         pgm-array)))))
"
        ))
(<p> "One can write a a routine to convolve an image with a filter as follows: ")
(<pre>
 (<code>"
(define (array-convolve source filter)
  (let* ((source-domain
          (array-domain source))
         (S_
          (array-getter source))
         (filter-domain
          (array-domain filter))
         (F_
          (array-getter filter))
         (result-domain
          (interval-dilate
           source-domain
           ;; the left bound of an interval is an equality,
           ;; the right bound is an inequality, hence the
           ;; the difference in the following two expressions
           (vector-map -
                       (interval-lower-bounds->vector filter-domain))
           (vector-map (lambda (x)
                         (- 1 x))
                       (interval-upper-bounds->vector filter-domain)))))
    (make-array result-domain
                (lambda (i j)
                  (array-fold
                   (lambda (p q)
                     (+ p q))
                   0
                   (make-array
                    filter-domain
                    (lambda (k l)
                      (* (S_ (+ i k)
                             (+ j l))
                         (F_ k l))))))
                )))
"))
(<p> "together with some filters")
(<pre>
 (<code>"
(define sharpen-filter
  (list->array
   '(0 -1  0
    -1  5 -1
     0 -1  0)
   (make-interval '#(-1 -1) '#(2 2))))

(define edge-filter
  (list->array
   '(0 -1  0
    -1  4 -1
     0 -1  0)
   (make-interval '#(-1 -1) '#(2 2))))
"))
(<p> "Our computations might results in pixel values outside the valid range, so we define ")
(<pre>
 (<code>"
(define (round-and-clip pixel max-grey)
  (max 0 (min (exact (round pixel)) max-grey)))
"))
(<p> "We can then compute edges and sharpen a test image as follows: ")
(<pre>
 (<code>"
(define test-pgm (read-pgm \"girl.pgm\"))

(let ((greys (pgm-greys test-pgm)))
  (write-pgm
   (make-pgm
    greys
    (array-map (lambda (p)
                 (round-and-clip p greys))
               (array-convolve
                (pgm-pixels test-pgm)
                sharpen-filter)))
   \"sharper-test.pgm\"))

(let* ((greys (pgm-greys test-pgm))
       (edge-array
        (array-copy
         (array-map
          abs
          (array-convolve
           (pgm-pixels test-pgm)
           edge-filter))))
       (max-pixel
        (array-fold max 0 edge-array))
       (normalizer
        (inexact (/ greys max-pixel))))
  (write-pgm
   (make-pgm
    greys
    (array-map (lambda (p)
                 (- greys
                    (round-and-clip (* p normalizer) greys)))
               edge-array))
   \"edge-test.pgm\"))
"))

(<p> (<b> "Viewing two-dimensional slices of three-dimensional data. ")"One example might be viewing two-dimensional slices of three-dimensional data in different ways.  If one has a $1024 \\times 512\\times 512$ 3D image of the body stored as a variable "(<code>(<var>'body))", then one could get 1024 axial views, each $512\\times512$, of this 3D body by "(<code> "(array-curry "(<var>'body)" 2)")"; or 512 median views, each $1024\\times512$, by "(<code> "(array-curry (array-permute "(<var>'body)" '#(1 0 2)) 2)")"; or finally 512 frontal views, each again $1024\\times512$ pixels, by "(<code> "(array-curry (array-permute "(<var>'body)" '#(2 0 1)) 2)")"; see "(<a> href: "https://en.wikipedia.org/wiki/Anatomical_plane" "Anatomical plane")".  Note that the first permutation is not a rotation"(string (integer->char 8212))"you want to have the head up in both the median and frontal views.")


(<p> (<b> "Calculating second differences of images. ")"For another example, if a real-valued function is defined
on a two-dimensional interval $I$, its second difference in the direction $d$ at the point $x$ is defined as $\\Delta^2_df(x)=f(x+2d)-2f(x+d)+f(x)$,
and this function is defined only for those $x$ for which $x$, $x+d$, and $x+2d$ are all in $I$. See the beginning of the section on \"Moduli of smoothness\" in "(<a> href: "https://www.math.purdue.edu/~lucier/692/related_papers_summaries.html#Wavelets-and-approximation-theory" "these notes on wavelets and approximation theory")" for more details.")
(<p> "Using this definition, the following code computes all second-order forward differences of an image in the directions
$d,2 d,3 d,\\ldots$, defined only on the domains where this makes sense: ")
(<pre>
 (<code>"
(define (all-second-differences image direction)
  (let ((image-domain (array-domain image)))
    (let loop ((i 1)
               (result '()))
      (let ((negative-scaled-direction
             (vector-map (lambda (j)
                           (* -1 j i))
                         direction))
            (twice-negative-scaled-direction
             (vector-map (lambda (j)
                           (* -2 j i))
                         direction)))
        (cond ((interval-intersect
                image-domain
                (interval-translate
                 image-domain
                 negative-scaled-direction)
                (interval-translate
                 image-domain
                 twice-negative-scaled-direction))
               =>
               (lambda (subdomain)
                 (loop
                  (+ i 1)
                  (cons
                   (array-copy
                    (array-map
                     (lambda (f_i f_i+d f_i+2d)
                       (+ f_i+2d
                          (* -2. f_i+d)
                          f_i))
                     (array-extract
                      image
                      subdomain)
                     (array-extract
                      (array-translate
                       image
                       negative-scaled-direction)
                      subdomain)
                     (array-extract
                      (array-translate
                       image
                       twice-negative-scaled-direction)
                      subdomain)))
                   result))))
              (else
               (reverse result)))))))
"))
(<p> "We can define a small synthetic image of size 8x8 pixels and compute its second differences in various directions: ")
(<pre>(<code> "
(define image
 (array-copy
  (make-array (make-interval '#(8 8))
              (lambda (i j)
                (exact->inexact (+ (* i i) (* j j)))))))

(define (expose difference-images)
  (pretty-print (map (lambda (difference-image)
                       (list (array-domain difference-image)
                             (array->list difference-image)))
                     difference-images)))

(begin
  (display
   \"\\nSecond-differences in the direction $k\\times (1,0)$:\\n\")
  (expose (all-second-differences image '#(1 0)))
  (display
   \"\\nSecond-differences in the direction $k\\times (1,1)$:\\n\")
  (expose (all-second-differences image '#(1 1)))
  (display
   \"\\nSecond-differences in the direction $k\\times (1,-1)$:\\n\")
  (expose (all-second-differences image '#(1 -1))))
"))
(<p> "On Gambit 4.8.5, this yields (after some hand editing): ")
(<pre> "
Second-differences in the direction $k\\times (1,0)$:
((#<##interval #2 lower-bounds: #(0 0) upper-bounds: #(6 8)>
 (2. 2. 2. 2. 2. 2. 2. 2. 2. 2. 2. 2. 2. 2. 2. 2.
  2. 2. 2. 2. 2. 2. 2. 2. 2. 2. 2. 2. 2. 2. 2. 2.
  2. 2. 2. 2. 2. 2. 2. 2. 2. 2. 2. 2. 2. 2. 2. 2.))
 (#<##interval #3 lower-bounds: #(0 0) upper-bounds: #(4 8)>
  (8. 8. 8. 8. 8. 8. 8. 8. 8. 8. 8. 8. 8. 8. 8. 8.
   8. 8. 8. 8. 8. 8. 8. 8. 8. 8. 8. 8. 8. 8. 8. 8.))
 (#<##interval #4 lower-bounds: #(0 0) upper-bounds: #(2 8)>
  (18. 18. 18. 18. 18. 18. 18. 18. 18.
   18. 18. 18. 18. 18. 18. 18.)))

Second-differences in the direction $k\\times (1,1)$:
((#<##interval #5 lower-bounds: #(0 0) upper-bounds: #(6 6)>
  (4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4.
   4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4.))
 (#<##interval #6 lower-bounds: #(0 0) upper-bounds: #(4 4)>
  (16. 16. 16. 16. 16. 16. 16. 16. 16. 16. 16. 16. 16. 16.
   16. 16.))
 (#<##interval #7 lower-bounds: #(0 0) upper-bounds: #(2 2)>
  (36. 36. 36. 36.)))

Second-differences in the direction $k\\times (1,-1)$:
((#<##interval #8 lower-bounds: #(0 2) upper-bounds: #(6 8)>
  (4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4.
   4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4. 4.))
 (#<##interval #9 lower-bounds: #(0 4) upper-bounds: #(4 8)>
  (16. 16. 16. 16. 16. 16. 16. 16. 16. 16. 16. 16. 16. 16.
   16. 16.))
 (#<##interval #10 lower-bounds: #(0 6) upper-bounds: #(2 8)>
  (36. 36. 36. 36.)))

")
(<p> "You can see that with differences in the direction of only the first coordinate, the domains of the difference arrays get smaller in the first coordinate while staying the same in the second coordinate, and with differences in the diagonal directions, the domains of the difference arrays get smaller in both coordinates.")



(<p> (<b> "Separable operators. ")"Many multi-dimensional transforms in signal processing are "(<i> 'separable)", in that the multi-dimensional transform can be computed by applying one-dimensional transforms in each of the coordinate directions.  Examples of such transforms include the Fast Fourier Transform and the "(<a> href: "https://arxiv.org/abs/1210.1944" "Fast Hyperbolic Wavelet Transform")".  Each one-dimensional subdomain of the complete domain is called a "(<i> 'pencil)", and the same one-dimensional transform is applied to all pencils in a given direction. Given the one-dimensional array transform, one can define the multidimensional transform as follows:")
(<pre> (<code>"
(define (make-separable-transform 1D-transform)
  (lambda (a)
    (let ((n (array-dimension a)))
      (do ((d 0 (fx+ d 1)))
          ((fx= d n))
        (array-for-each
         1D-transform
         (array-curry (array-rotate a d) 1))))))
"))
(<p> "Here we have cycled through all rotations, putting each axis in turn at the end, and then applied "(<code>'1D-transform)" to each of the pencils along that axis.")
(<p> "Wavelet transforms in particular are calculated by recursively applying a transform to an array and then downsampling the array; the inverse transform recursively downsamples and then applies a transform.  So we define the following primitives: ")
(<pre>(<code>"
(define (recursively-apply-transform-and-downsample transform)
  (lambda (a)
    (let ((sample-vector (make-vector (array-dimension a) 2)))
      (define (helper a)
        (if (fx< 1 (interval-upper-bound (array-domain a) 0))
            (begin
              (transform a)
              (helper (array-sample a sample-vector)))))
      (helper a))))

(define (recursively-downsample-and-apply-transform transform)
  (lambda (a)
    (let ((sample-vector (make-vector (array-dimension a) 2)))
      (define (helper a)
        (if (fx< 1 (interval-upper-bound (array-domain a) 0))
            (begin
              (helper (array-sample a sample-vector))
              (transform a))))
      (helper a))))
"))
(<p>  "By adding a single loop that calculates scaled sums and differences of adjacent elements in a one-dimensional array, we can define various "(<a> id: "Haar" "Haar wavelet transforms")" as follows:")
(<pre>(<code>"
(define (1D-Haar-loop a)
  (let ((a_ (array-getter a))
        (a! (array-setter a))
        (n (interval-upper-bound (array-domain a) 0)))
    (do ((i 0 (fx+ i 2)))
        ((fx= i n))
      (let* ((a_i               (a_ i))
             (a_i+1             (a_ (fx+ i 1)))
             (scaled-sum        (fl/ (fl+ a_i a_i+1) (flsqrt 2.0)))
             (scaled-difference (fl/ (fl- a_i a_i+1) (flsqrt 2.0))))
        (a! scaled-sum i)
        (a! scaled-difference (fx+ i 1))))))

(define 1D-Haar-transform
  (recursively-apply-transform-and-downsample 1D-Haar-loop))

(define 1D-Haar-inverse-transform
  (recursively-downsample-and-apply-transform 1D-Haar-loop))

(define hyperbolic-Haar-transform
  (make-separable-transform 1D-Haar-transform))

(define hyperbolic-Haar-inverse-transform
  (make-separable-transform 1D-Haar-inverse-transform))

(define Haar-transform
  (recursively-apply-transform-and-downsample
   (make-separable-transform 1D-Haar-loop)))

(define Haar-inverse-transform
  (recursively-downsample-and-apply-transform
   (make-separable-transform 1D-Haar-loop)))
"))
(<p> "We then define an image that is a multiple of a single, two-dimensional hyperbolic Haar wavelet, compute its hyperbolic Haar transform (which should have only one nonzero coefficient), and then the inverse transform:")
(<pre>
 (<code>"
(let ((image
       (array-copy
        (make-array (make-interval '#(4 4))
                    (lambda (i j)
                      (case i
                        ((0) 1.)
                        ((1) -1.)
                        (else 0.)))))))
  (display \"\nInitial image:\n\")
  (pretty-print (list (array-domain image)
                      (array->list image)))
  (hyperbolic-Haar-transform image)
  (display \"\\nArray of hyperbolic Haar wavelet coefficients: \\n\")
  (pretty-print (list (array-domain image)
                      (array->list image)))
  (hyperbolic-Haar-inverse-transform image)
  (display \"\\nReconstructed image: \\n\")
  (pretty-print (list (array-domain image)
                      (array->list image))))
"))
(<p> "This yields: ")
(<pre>"
Initial image:
(#<##interval #11 lower-bounds: #(0 0) upper-bounds: #(4 4)>
 (1. 1. 1. 1. -1. -1. -1. -1. 0. 0. 0. 0. 0. 0. 0. 0.))

Array of hyperbolic Haar wavelet coefficients:
(#<##interval #11 lower-bounds: #(0 0) upper-bounds: #(4 4)>
 (0. 0. 0. 0. 2.8284271247461894 0. 0. 0. 0. 0. 0. 0. 0. 0. 0. 0.))

Reconstructed image:
(#<##interval #11 lower-bounds: #(0 0) upper-bounds: #(4 4)>
 (.9999999999999996
  .9999999999999996
  .9999999999999996
  .9999999999999996
  -.9999999999999996
  -.9999999999999996
  -.9999999999999996
  -.9999999999999996
  0.
  0.
  0.
  0.
  0.
  0.
  0.
  0.))
" )
(<p> "In perfect arithmetic, this hyperbolic Haar transform is "(<i>'orthonormal)", in that the sum of the squares of the elements of the image is the same as the sum of the squares of the hyperbolic Haar coefficients of the image.  We can see that this is approximately true here.")

(<p> "We can apply the (nonhyperbolic) Haar transform to the same image as follows: ")
(<pre>(<code>"
 (let ((image
       (array-copy
        (make-array (make-interval '#(4 4))
                    (lambda (i j)
                      (case i
                        ((0) 1.)
                        ((1) -1.)
                        (else 0.)))))))
  (display \"\\nInitial image:\\n\")
  (pretty-print (list (array-domain image)
                      (array->list image)))
  (Haar-transform image)
  (display \"\\nArray of Haar wavelet coefficients: \\n\")
  (pretty-print (list (array-domain image)
                      (array->list image)))
  (Haar-inverse-transform image)
  (display \"\\nReconstructed image: \\n\")
  (pretty-print (list (array-domain image)
                      (array->list image))))
"))
(<p> "This yields: ")
(<pre>"
Initial image:
(#<##interval #12 lower-bounds: #(0 0) upper-bounds: #(4 4)>
 (1. 1. 1. 1. -1. -1. -1. -1. 0. 0. 0. 0. 0. 0. 0. 0.))

Array of Haar wavelet coefficients:
(#<##interval #12 lower-bounds: #(0 0) upper-bounds: #(4 4)>
 (0. 0. 0. 0. 1.9999999999999998 0. 1.9999999999999998 0. 0. 0. 0. 0. 0. 0. 0. 0.))

Reconstructed image:
(#<##interval #12 lower-bounds: #(0 0) upper-bounds: #(4 4)>
 (.9999999999999997
  .9999999999999997
  .9999999999999997
  .9999999999999997
  -.9999999999999997
  -.9999999999999997
  -.9999999999999997
  -.9999999999999997
  0.
  0.
  0.
  0.
  0.
  0.
  0.
  0.))
")
(<p> "You see in this example that this particular image has two, not one, nonzero coefficients in the two-dimensional Haar transform, which is again approximately orthonormal.")

(<p> (<b> "Matrix multiplication and Gaussian elimination. ")"While we have avoided conflating matrices and arrays, we give here some examples of matrix operations defined using operations from this SRFI.")
(<p> "Given a nonsingular square matrix $A$ we can overwrite $A$ with lower-triangular matrix $L$ with ones on the diagonal and upper-triangular
matrix $U$ so that $A=LU$ as follows. (We assume \"pivoting\" isn't needed.) For example, if "
     "$$A=\\begin{pmatrix} a_{11}&a_{12}&a_{13}\\\\ a_{21}&a_{22}&a_{23}\\\\ a_{31}&a_{32}&a_{33}\\end{pmatrix}=\\begin{pmatrix} 1&0&0\\\\ \\ell_{21}&1&0\\\\ \\ell_{31}&\\ell_{32}&1\\end{pmatrix}\\begin{pmatrix} u_{11}&u_{12}&u_{13}\\\\ 0&u_{22}&u_{23}\\\\ 0&0&u_{33}\\end{pmatrix}$$ then $A$ is overwritten with
$$
\\begin{pmatrix} u_{11}&u_{12}&u_{13}\\\\ \\ell_{21}&u_{22}&u_{23}\\\\ \\ell_{31}&\\ell_{32}&u_{33}\\end{pmatrix}.
$$
The code uses "(<code>'array-assign!)", "(<code>'specialized-array-share)", "(<code>'array-extract)", and "(<code>'array-outer-product)".")
(<pre>
 (<code>"
(define (LU-decomposition A)
  ;; Assumes the domain of A is [0,n)\\times [0,n)
  ;; and that Gaussian elimination can be applied
  ;; without pivoting.
  (let ((n
         (interval-upper-bound (array-domain A) 0))
        (A_
         (array-getter A)))
    (do ((i 0 (fx+ i 1)))
        ((= i (fx- n 1)) A)
      (let* ((pivot
              (A_ i i))
             (column/row-domain
              ;; both will be one-dimensional
              (make-interval (vector (+ i 1))
                             (vector n)))
             (column
              ;; the column below the (i,i) entry
              (specialized-array-share A
                                       column/row-domain
                                       (lambda (k)
                                         (values k i))))
             (row
              ;; the row to the right of the (i,i) entry
              (specialized-array-share A
                                       column/row-domain
                                       (lambda (k)
                                         (values i k))))

             ;; the subarray to the right and
             ;; below the (i,i) entry
             (subarray
              (array-extract
               A (make-interval
                  (vector (fx+ i 1) (fx+ i 1))
                  (vector n         n)))))
        ;; Compute multipliers.
        (array-assign!
         column
         (array-map (lambda (x)
                      (/ x pivot))
                    column))
        ;; Subtract the outer product of i'th
        ;; row and column from the subarray.
        (array-assign!
         subarray
         (array-map -
                    subarray
                    (array-outer-product * column row)))))))
"))
(<p> "We then define a $4\\times 4$ "(<a> href: "https://en.wikipedia.org/wiki/Hilbert_matrix" "Hilbert matrix")":")
(<pre>
 (<code>"
(define A
  (array-copy
   (make-array (make-interval '#(4 4))
               (lambda (i j)
                 (/ (+ 1 i j))))))

(define (array-display A)
  
  (define (display-item x)
    (display x) (display \"\\t\"))
  
  (newline)
  (case (array-dimension A)
    ((1) (array-for-each display-item A) (newline))
    ((2) (array-for-each (lambda (row)
                           (array-for-each display-item row)
                           (newline))
                         (array-curry A 1)))
    (else
     (error \"array-display can't handle > 2 dimensions: \" A))))

(display \"\\nHilbert matrix:\\n\\n\")

(array-display A)

;;; which displays:
;;; 1       1/2     1/3     1/4
;;; 1/2     1/3     1/4     1/5
;;; 1/3     1/4     1/5     1/6
;;; 1/4     1/5     1/6     1/7

(LU-decomposition A)

(display \"\\nLU decomposition of Hilbert matrix:\\n\\n\")

(array-display A)

;;; which displays:
;;; 1       1/2     1/3     1/4
;;; 1/2     1/12    1/12    3/40
;;; 1/3     1       1/180   1/120
;;; 1/4     9/10    3/2     1/2800

"))
(<p> "We can now define matrix multiplication as follows to check our result:")
(<pre>
 (<code>"
;;; Functions to extract the lower- and upper-triangular
;;; matrices of the LU decomposition of A.

(define (L a)
  (let ((a_ (array-getter a))
        (d  (array-domain a)))
    (make-array
     d
     (lambda (i j)
       (cond ((= i j) 1)        ;; diagonal
             ((> i j) (a_ i j)) ;; below diagonal
             (else 0))))))      ;; above diagonal

(define (U a)
  (let ((a_ (array-getter a))
        (d  (array-domain a)))
    (make-array
     d
     (lambda (i j)
       (cond ((<= i j) (a_ i j)) ;; diagonal and above
             (else 0))))))       ;; below diagonal

(display \"\\nLower triangular matrix of decomposition of Hilbert matrix:\\n\\n\")
(array-display (L A))

;;; which displays:
;;; 1       0       0       0
;;; 1/2     1       0       0
;;; 1/3     1       1       0
;;; 1/4     9/10    3/2     1


(display \"\\nUpper triangular matrix of decomposition of Hilbert matrix:\\n\\n\")
(array-display (U A))

;;; which displays:
;;; 1       1/2     1/3     1/4
;;; 0       1/12    1/12    3/40
;;; 0       0       1/180   1/120
;;; 0       0       0       1/2800

;;; We'll define a brief, not-very-efficient matrix multiply routine.

(define (array-dot-product a b)
  (array-fold + 0 (array-map * a b)))

(define (matrix-multiply a b)
  (let ((a-rows
         (array-copy (array-curry a 1)))
        (b-columns
         (array-copy (array-curry (array-rotate b 1) 1))))
    (array-outer-product array-dot-product a-rows b-columns)))

;;; We'll check that the product of the result of LU
;;; decomposition of A is again A.

(define product (matrix-multiply (L A) (U A)))

(display \"\\nProduct of lower and upper triangular matrices \\n\")
(display \"of LU decomposition of Hilbert matrix:\\n\\n\")
(array-display product)

;;; which displays:
;;; 1       1/2     1/3     1/4
;;; 1/2     1/3     1/4     1/5
;;; 1/3     1/4     1/5     1/6
;;; 1/4     1/5     1/6     1/7
"))
(<p> (<b> "Inner products. ")"One can define an APL-style inner product as")
(<pre>
 (<code>"
(define (inner-product A f g B)
  (array-outer-product
   (lambda (a b)
     (array-reduce f (array-map g a b)))
   (array-copy (array-curry A 1))
   (array-copy (array-curry (array-rotate B 1) 1))))
"))
(<p> "This routine differs from that found in APL in several ways: The arguments "(<code>(<var>'A))" and "(<code>(<var>'B))" must each have two or more dimensions, and the result is always an array, never a scalar.")
(<p> "We take some examples from the "(<a> href: "https://www.dyalog.com/uploads/aplx/APLXLangRef.pdf" "APLX Language Reference")":")
(<pre>
 (<code>"
;; Examples from
;; http://microapl.com/apl_help/ch_020_020_880.htm 
   
(define TABLE1
  (list->array
   '(1 2
     5 4
     3 0)
   (make-interval '#(3 2))))

(define TABLE2
  (list->array
   '(6 2 3 4
     7 0 1 8)
   (make-interval '#(2 4))))

(array-display (inner-product TABLE1 + * TABLE2))

;;; Displays
;;; 20      2       5       20
;;; 58      10      19      52
;;; 18      6       9       12

(define X   ;; a \"row vector\"
  (list->array '(1 3 5 7) (make-interval '#(1 4))))

(define Y   ;; a \"column vector\"
  (list->array '(2 3 6 7) (make-interval '#(4 1))))

(array-display (inner-product X + (lambda (x y) (if (= x y) 1 0)) Y))

;;; Displays
;;; 2
"))
(<h2> "Acknowledgments")
(<p> "The SRFI author thanks Edinah K Gnang, John Cowan, Sudarshan S Chawathe, Jamison Hope, and Per Bothner for their comments and suggestions, and Arthur A. Gleckler, SRFI Editor, for his guidance and patience.")
(<h2> "References")
(<ol>
 (<li> (<a> id: 'bawden href: "https://groups.google.com/forum/?hl=en#!msg/comp.lang.scheme/7nkx58Kv6RI/a5hdsduFL2wJ" "\"multi-dimensional arrays in R5RS?\"")
       ", by Alan Bawden.")
 (<li> (<a> id: 'SRFI-4  href: "https://srfi.schemers.org/srfi-4/"  "SRFI 4:  Homogeneous Numeric Vector Datatypes")", by Marc Feeley.")
 (<li> (<a> id: 'SRFI-25 href: "https://srfi.schemers.org/srfi-25/" "SRFI 25: Multi-dimensional Array Primitives")", by Jussi Piitulainen.")
 (<li> (<a> id: 'SRFI-47 href: "https://srfi.schemers.org/srfi-47/" "SRFI 47: Array")", by Aubrey Jaffer.")
 (<li> (<a> id: 'SRFI-58 href: "https://srfi.schemers.org/srfi-58/" "SRFI 58: Array Notation")", by Aubrey Jaffer.")
 (<li> (<a> id: 'SRFI-63 href: "https://srfi.schemers.org/srfi-63/" "SRFI 63: Homogeneous and Heterogeneous Arrays")", by Aubrey Jaffer.")
 (<li> (<a> id: 'SRFI-164 href: "https://srfi.schemers.org/srfi-164/" "SRFI 164: Enhanced multi-dimensional Arrays")", by Per Bothner."))
(<h2> "Copyright")
(<p> (<unprotected> "&copy;")" 2016, 2018, 2020 Bradley J Lucier. All Rights Reserved.")
(<p> "Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: ")
(<p> "The above copyright notice and this permission notice (including the next paragraph) shall be included in all copies or substantial portions of the Software.")
(<p> " THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
")
(<hr>)
(<address> "Editor: " (<a> href: "mailto:srfi-editors+at+srfi+dot+schemers+dot+org" "Arthur A. Gleckler"))
))))))
