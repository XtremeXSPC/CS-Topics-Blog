---
author: LCS.Dev
date: 2025-08-26T22:10:00.000535
title: A Number Theory Problem
description: Sea, you & copriMe - Analysis.
draft: false
math: true
showToc: true
TocOpen: false
UseHugoToc: true
hidemeta: false
comments: false
disableHLJS: false
disableShare: false
hideSummary: false
searchHidden: true
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
tags:
  - Competitive-Programming
  - Coding
categories:
  - Math
  - Programming
  - C++
cover:
  image:
  alt:
  caption:
  relative: false
  hidden: true
editPost:
  URL: https://github.com/XtremeXSPC/LCS.Dev-Blog/tree/hostinger/
  Text: Suggest Changes
  appendFilePath: true
---

# Finding coprime quadruples

## An algorithmic analysis of "Sea, you & copriMe"

---

## Abstract

This article presents a comprehensive algorithmic analysis and solution to the problem of finding quadruples of distinct indices in an integer array that form two coprime pairs. While originating from competitive programming, this problem offers an excellent opportunity to explore the intersections between number theory, graph theory, and efficient algorithm design. I will demonstrate how the combination of concepts such as the Sieve of Eratosthenes, the Möbius function, the inclusion-exclusion principle, enables the development of a robust and elegant solution. The final implementation demonstrates how deep understanding of underlying mathematical properties is fundamental to achieving decisive algorithmic optimizations.

---

## Introduction

The original Codeforces problem "Sea, You & copriMe" asks for four distinct indices $p, q, r, s$ such that

$$
\gcd(a_p, a_q) = 1
\qquad\text{and}\qquad
\gcd(a_r, a_s) = 1.
$$

At first glance this looks like a brute-force search over quadruples, which would be completely infeasible under the official constraints:

- $4 \le n \le 2 \cdot 10^5$
- $1 \le a_i \le m \le 10^6$
- over all test cases, $\sum n \le 2 \cdot 10^5$ and $\sum m \le 10^6$

The key to a clean solution is to stop thinking about four indices directly. The problem is better understood as a question about matchings in a graph whose edges are defined by coprimality. Once that reformulation is in place, number theory provides the right counting tool: Möbius inversion. The final implementation is therefore not a collection of ad hoc cases, but a structured combination of:

- a graph-theoretic reduction;
- an exact counting formula for coprime neighbors;
- an efficient search over admissible first edges;
- a linear reconstruction of the second edge.

This article presents that improved solution in a formal and implementation-aware way.

## Problem statement

For each test case we are given an array $a = (a_1, a_2, \dots, a_n)$. We must output either:

- four distinct indices $p, q, r, s$ such that both pairs are coprime;
- or `0` if no such quadruple exists.

Any valid quadruple is acceptable.

## From four indices to two edges

Define the **coprimality graph** $G = (V, E)$ as follows:

- $V = \{1, 2, \dots, n\}$;
- $(i, j) \in E$ if and only if $i \ne j$ and $\gcd(a_i, a_j) = 1$.

Under this definition, the problem becomes:

> Find a matching of size $2$ in $G$.

That is, we need two disjoint edges. This is much simpler than general maximum matching: we do not need Blossom or any heavy graph algorithm, because the target size is fixed and very small.

For each vertex $i$, let

$$
\deg(i) = \bigl|\{j \ne i : \gcd(a_i, a_j) = 1\}\bigr|
$$

be its degree in the coprimality graph, and let

$$
K = |E| = \frac{1}{2}\sum_{i=1}^{n}\deg(i)
$$

be the total number of coprime pairs in the array. The entire strategy will revolve around the quantities $\deg(i)$ and $K$.

## Which first edge is good enough?

Suppose that $(u, v)$ is a coprime pair and we choose it as the first edge of the matching. After removing the vertices $u$ and $v$, every edge incident to either endpoint disappears. The number of deleted edges is exactly

$$
\deg(u) + \deg(v) - 1,
$$

because the edge $(u, v)$ itself is counted in both degrees. Therefore the remaining graph still contains an edge if and only if

$$
K - \bigl(\deg(u) + \deg(v) - 1\bigr) > 0.
$$

Since all terms are integers, this is equivalent to

$$
\deg(u) + \deg(v) \le K.
$$

This gives an exact criterion.

**Proposition.**
A valid answer exists if and only if there is an edge $(u, v)$ such that

$$
\gcd(a_u, a_v) = 1
\qquad\text{and}\qquad
\deg(u) + \deg(v) \le K.
$$

**Why this matters.**
The original four-index problem is reduced to the search for a single edge satisfying a degree bound. Once such an edge is found, any remaining edge in the residual graph will complete the answer.

### A small example

Consider the sample array

$$
[4, 7, 9, 15].
$$

Its coprime degrees are

$$
\deg(4)=3,\quad \deg(7)=3,\quad \deg(9)=2,\quad \deg(15)=2,
$$

so

$$
K = \frac{3+3+2+2}{2}=5.
$$

The pair $(9, 4)$ is coprime and satisfies

$$
\deg(9)+\deg(4)=2+3=5 \le K.
$$

Hence it is a valid first edge. After removing the corresponding vertices, the edge $(7, 15)$ still remains, so the instance is solvable.

## Counting degrees with Möbius inversion

The graph reformulation is only useful if degrees can be computed efficiently. Checking all $O(n^2)$ pairs is impossible, so we count coprime neighbors indirectly.

For every integer $d \in [1, m]$, define

$$
C[d] = \bigl|\{i : d \mid a_i\}\bigr|,
$$

the number of array elements divisible by $d$. Now recall the classical identity

$$
\sum_{d \mid g}\mu(d) =
\begin{cases}
1 & \text{if } g = 1, \\
0 & \text{if } g > 1,
\end{cases}
$$

where $\mu$ is the Möbius function. Applying it with $g = \gcd(x, y)$ yields

$$
\sum_{d \mid \gcd(x, y)} \mu(d) =
\begin{cases}
1 & \text{if } \gcd(x, y) = 1, \\
0 & \text{otherwise.}
\end{cases}
$$

Summing over all array elements gives the number of values coprime with a fixed $x$:

$$
\sum_{d \mid x} \mu(d)\, C[d].
$$
Hence, for every index $i$,

$$
\deg(i) = \sum_{d \mid a_i} \mu(d)\, C[d] - [a_i = 1].
$$

The correction term is needed only for the value $1$, because the formula counts the index itself when $\gcd(1,1)=1$.

### Computing the Möbius function

The implementation performs one global linear sieve up to $10^6$. It stores:

- `g_mu[x]`, the Möbius value of $x$;
- `g_spf[x]`, the smallest prime factor of $x$.

The sieve is executed once before processing the test cases, so its total cost is $O(10^6)$.

### Computing the multiples counts

The array `mult_cnt` in the implementation corresponds exactly to the function $C[d]$. It is built by the standard divisor transform:

$$
C[d] = \sum_{k \ge 1} \text{freq}[kd].
$$

Operationally:

```text
for d = 1 .. m
    for x = d, 2d, 3d, ... <= m
        C[d] += freq[x]
```

This takes

$$
O\!\left(\sum_{d=1}^{m}\frac{m}{d}\right) = O(m \log m).
$$

### Enumerating divisors

For each value $a_i$, the implementation uses `g_spf` to factor it and then builds the full list of divisors. This may look slightly wasteful because non-square-free divisors have Möbius value $0$, but for $a_i \le 10^6$ the number of divisors is small enough that the approach remains efficient and very simple to implement.

This is precisely what the degree computation loop evaluates:

```cpp
FOR(i, n) {
  divisors[i] = build_divisors(a[i]);
  I32 d = 0;
  for (const I32 div : divisors[i]) d += g_mu[div] * mult_cnt[div];
  if (a[i] == 1) --d;
  deg[i] = d;
  total_edges2 += d;
}
```

Once all degrees are known, we obtain

$$
K = \frac{1}{2}\sum_i \deg(i).
$$

If $K = 0$, then the graph has no edge at all and the answer is immediately `0`.

## Searching for the first edge

We now know exactly what we need: an edge $(u, v)$ such that

$$
\deg(u) + \deg(v) \le K.
$$

The challenge is to search for such an edge without testing too many pairs.

### Step 1: Sort vertices by degree

Let

$$
p_0, p_1, \dots, p_{n-1}
$$

be the indices sorted by nondecreasing degree. For a fixed position $i$, define

$$
R(i) = \max \{j : j > i \text{ and } \deg(p_j) \le K - \deg(p_i)\},
$$

with the convention that $R(i) < i+1$ when the set is empty. Then every admissible partner of $p_i$ must lie in the interval

$$
\{p_{i+1}, p_{i+2}, \dots, p_{R(i)}\}.
$$

In the code, this boundary is stored in the array `reach`.

### Step 2: Observe that the windows shrink monotonically

Because the degrees are sorted, $\deg(p_i)$ is nondecreasing, so the bound $K - \deg(p_i)$ is non-increasing. Therefore the sequence $R(i)$ is also non-increasing.

This is the crucial structural fact that turns the search into a sliding-window problem: as $i$ increases, the set of admissible partners only shrinks.

### Step 3: Maintain divisibility counts on the active window

For the current vertex $p_i$, define the active window

$$
A_i = \{p_{i+1}, \dots, p_{R(i)}\}.
$$

For each divisor $d$, maintain the quantity

$$
M_i(d) = \bigl|\{x \in A_i : d \mid a_x\}\bigr|.
$$

Then the number of vertices in the active window that are coprime with $a_{p_i}$ is

$$
\sum_{d \mid a_{p_i}} \mu(d)\, M_i(d).
$$

This is the same Möbius formula as before, but applied to a dynamic subset rather than to the entire array.

The implementation uses the helper lambda:

```cpp
auto modify_pos = [&](const I32 pos, const I32 delta) {
  const I32 id = order[pos];
  for (const I32 div : divisors[id]) active_mult[div] += delta;
};
```

so that each vertex enters and leaves the active window exactly once.

### Step 4: Use counting first, GCD later

For each $i$:

1. compute how many active vertices are coprime with $p_i$ using the Möbius sum;
2. if the answer is zero, no admissible partner exists for this $i$;
3. if the answer is positive, linearly scan the interval
   $\{p_{i+1}, \dots, p_{R(i)}\}$ until a concrete partner is found by `gcd`.

The important point is that the expensive linear scan is performed at most once: the first time the Möbius count is positive, the algorithm immediately finds a valid first edge and stops.

In pseudocode, the search is:

```text
sort indices by degree
compute R(i) for every i
initialize active window for i = 0

for i = 0 .. n-1
    if A_i is non-empty
        count coprimes of p_i inside A_i using Möbius
        if count > 0
            scan A_i until a gcd-1 partner is found
            output this pair as the first edge
            stop
    slide the window to A_{i+1}
```

### Why this search is complete

The method is not heuristic.

Take any valid first edge $(u, v)$ and assume that $u$ appears before $v$ in the degree-sorted order, say $u = p_i$ and $v = p_j$. Since the edge is valid,

$$
\deg(u) + \deg(v) \le K,
$$

which implies $j \le R(i)$. Therefore $v$ belongs to the active window $A_i$. Since $\gcd(a_u, a_v)=1$, the Möbius count on $A_i$ is strictly positive, so the algorithm must detect some admissible partner while processing $i$.

Consequently, if the search phase fails, then no valid first edge exists and the answer is necessarily `0`.

## Reconstructing the second edge

Once the first edge $(u, v)$ has been selected, we remove its contribution from the global divisibility counts. Let $C_{\mathrm{rem}}[d]$ denote the number of remaining elements divisible by $d$. In the code this is done by copying `mult_cnt` into `rem_mult` and decrementing all divisors of $a_u$ and $a_v$.

For every remaining index $i$, we compute its degree in the residual graph:

$$
\deg_{\mathrm{rem}}(i) =
\sum_{d \mid a_i}\mu(d)\, C_{\mathrm{rem}}[d] - [a_i = 1].
$$

If $\deg_{\text{rem}}(i) > 0$, then there exists at least one remaining index $j$ such that $\gcd(a_i, a_j)=1$. A direct scan recovers one such $j$, and the quadruple

$$
(u, v, i, j)
$$

is a correct answer.

This stage is also efficient:

- the Möbius test is applied to each remaining index only once;
- the linear scan is executed only for the first index whose residual degree is positive;
- therefore reconstruction is linear after divisor preprocessing.

## Correctness proof

We can now summarize the argument formally.

**Lemma 1.**
For every index $i$,

$$
\deg(i) = \sum_{d \mid a_i} \mu(d)\, C[d] - [a_i = 1].
$$

**Proof.**
For each array element $a_j$,

$$
\sum_{d \mid \gcd(a_i, a_j)} \mu(d)
$$

is $1$ exactly when $\gcd(a_i, a_j)=1$, and $0$ otherwise. Summing over all $j$ produces the number of coprime neighbors of $i$. The only self-count occurs when $a_i=1$, so we subtract that term. $\square$

**Lemma 2.**
Let $(u, v)$ be an edge of the coprimality graph. After removing $u$ and $v$, the number of remaining edges is

$$
K - \bigl(\deg(u)+\deg(v)-1\bigr).
$$

**Proof.**
All deleted edges are exactly those incident to $u$ or $v$. Their total number is $\deg(u)+\deg(v)$, except that the edge $(u, v)$ is counted twice. $\square$

**Lemma 3.**
An edge $(u, v)$ can be the first edge of a valid answer if and only if

$$
\deg(u)+\deg(v) \le K.
$$

**Proof.**
By Lemma 2, the residual graph contains at least one edge if and only if

$$
K - \bigl(\deg(u)+\deg(v)-1\bigr) > 0.
$$

This is equivalent to $\deg(u)+\deg(v) \le K$. $\square$

**Lemma 4.**
If there exists a valid first edge, the search phase finds one.

**Proof.**
Take a valid first edge $(u, v)$ with $u = p_i$ and $v = p_j$ in the degree-sorted order, where $i < j$. By Lemma 3, $\deg(v) \le K - \deg(u)$, hence $j \le R(i)$ and $v \in A_i$. Since $u$ and $v$ are coprime, the Möbius count on $A_i$ is positive, so the algorithm detects a partner while processing $i$. $\square$

**Lemma 5.**
If the reconstruction phase outputs $(u, v, r, s)$, then the answer is correct.

**Proof.**
The indices are distinct by construction. The pair $(u, v)$ is coprime because it is chosen from the search phase via an explicit `gcd` check. The pair $(r, s)$ is coprime because `gcd(a_r, a_s)=1` is checked before output. $\square$

**Theorem.**
For every test case, the algorithm outputs `0` if and only if no valid quadruple exists; otherwise it outputs four distinct indices satisfying the required condition.

**Proof.**
If the algorithm outputs a quadruple, Lemma 5 proves correctness. If it outputs `0`, then either $K=0$, in which case no coprime pair exists at all, or the search phase fails. By Lemma 4, failure of the search phase implies that no valid first edge exists. By Lemma 3, no matching of size $2$ can then exist. $\square$

## Complexity analysis

Let $A = 10^6$ be the maximum possible value of an array element.

### Global precomputation

- Linear sieve for `g_mu` and `g_spf`: $O(A)$ time, $O(A)$ memory.

This cost is paid once for the entire input.

### Per test case

Let $\tau(x)$ denote the number of divisors of $x$.

- Frequency table and multiples transform: $O(m \log m)$
- Divisor generation and degree evaluation:
  $O\!\left(\sum_{i=1}^{n}\tau(a_i)\right)$
- Sorting the indices by degree: $O(n \log n)$
- Sliding-window search:
  $O\!\left(\sum_{i=1}^{n}\tau(a_i) + n\right)$
- Reconstruction:
  $O\!\left(\sum_{i=1}^{n}\tau(a_i) + n\right)$

Hence the overall complexity per test case is

$$
O\!\left(m \log m + n \log n + \sum_{i=1}^{n}\tau(a_i)\right).
$$

This is comfortably within the contest limits. In particular, for numbers up to $10^6$, the divisor count is small, and the global constraints

$$
\sum n \le 2 \cdot 10^5,
\qquad
\sum m \le 10^6
$$

keep the total workload well under control.

The memory usage is dominated by a handful of arrays of size $m+1$ together with the stored divisor lists, so it remains linear in the input scale.

## Notes on the C++ Implementation

The final code uses the aliases and loop macros from my template library:

- `I32`, `I64` for fixed-width integers;
- `VecI32` and `Vec2D<I32>` for vectors;
- `FOR(...)` for concise loop syntax;
- `as<T>(x)` for explicit casts.

These are purely syntactic conveniences. The mathematical content of the algorithm is unchanged:

- `mult_cnt` implements the global multiples counts $C[d]$;
- `active_mult` implements the dynamic counts denoted in the article by $M_i(d)$;
- the Möbius sum is used twice, once for the full graph and once for the active subset;
- `reach[i]` encodes the degree bound $\deg(p_j) \le K - \deg(p_i)$.

This is one of the reasons I like this version of the solution more than the original one: the implementation mirrors the proof very closely. You can find the complete solution here: [problem_H.cpp](https://gist.github.com/XtremeXSPC/a1ff88dc70f744c2170373979508e3a1)

## Conclusion

The central idea of the problem is not "how do I search four indices quickly?", but "how do I certify that one coprime pair leaves another coprime pair behind?" The exact answer is the inequality

$$
\deg(u)+\deg(v) \le K.
$$

Once the coprimality graph is viewed through that lens, Möbius inversion becomes the natural counting tool, and the rest of the algorithm follows from a clean sequence of reductions:

1. count coprime neighbors efficiently;
2. search exhaustively among degree-feasible first edges;
3. reconstruct the remaining edge.

The result is a solution that is mathematically precise, asymptotically efficient, and much cleaner than a case-by-case treatment of special values.