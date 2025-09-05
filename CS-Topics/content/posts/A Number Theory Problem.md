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
# Finding coprime quadruples: An algorithmic analysis of "Sea, you & copriMe"

## Abstract

This article presents a comprehensive algorithmic analysis and solution to the problem of finding quadruples of distinct indices in an integer array that form two coprime pairs. While originating from competitive programming, this problem offers an excellent opportunity to explore the intersections between number theory, graph theory, and efficient algorithm design. We demonstrate how the combination of concepts such as the Sieve of Eratosthenes, the Möbius function, the inclusion-exclusion principle, and heuristic search strategies enables the development of a robust and elegant solution. The final implementation demonstrates how deep understanding of underlying mathematical properties is fundamental to achieving decisive algorithmic optimizations.

---

## 1. Problem formulation and introduction

In the realm of algorithmic problem solving, certain challenges distinguish themselves through an apparently simple formulation that conceals considerable computational complexity. The problem under examination, titled "Sea, You & copriMe," belongs entirely to this category. Its formal definition is as follows:

**Input:**

- An array $a$ of $n$ integers, where $4 \leq n \leq 200,000$
- Each element $a_i$ of the array is within the interval $[1, m]$, where $1 \leq m \leq 1,000,000$

**Output:**

- Four distinct indices $(p, q, r, s)$ such that the greatest common divisor of the corresponding element pairs is unity:
    - $\gcd(a_p, a_q) = 1$
    - $\gcd(a_r, a_s) = 1$
- If no such quadruple exists, the output should be `0`

The primary challenge lies in the dimensional constraints of the input. A brute force approach examining all possible combinations of four indices would result in $O(n^4)$ time complexity, a prohibitive value for $n$ on the order of $2 \times 10^5$. It is therefore imperative to develop a strategy that exploits the intrinsic mathematical structure of the problem to drastically reduce the solution space to be explored.

---

## 2. The coprimality graph: a structural perspective

A fundamental initial insight for approaching this problem consists of reformulating it in terms of graph theory. We can model the coprimality relationships between array elements through an undirected graph $G = (V, E)$, defined as follows:

- The vertex set $V = {1, 2, \ldots, n}$ represents the indices of array $a$
- An edge $(i, j)$ belongs to the edge set $E$ if and only if the corresponding elements are coprime, i.e., $\gcd(a_i, a_j) = 1$

In this new perspective, the problem translates to finding two edges in $G$ that share no vertices, essentially a **matching** of size two. This abstraction not only clarifies the problem structure but also opens the way to various algorithmic strategies based on graph properties.

We define the **coprimality degree** of a vertex $i$ as the number of edges incident to it, which corresponds to the number of elements in the array that are coprime with $a_i$:

$$\deg(i) = |{j \in V, j \neq i \mid \gcd(a_i, a_j) = 1}|$$

Elements with low coprimality degree represent "scarce resources" in our graph. For example, a vertex with degree 1 (a "leaf vertex") has only one potential partner to form a coprime pair. Prioritized management of such vertices will prove to be an effective heuristic strategy.

---

## 3. Fundamental tools from number theory

To navigate efficiently in the coprimality graph, particularly to calculate vertex degrees, it is necessary to resort to advanced tools from number theory.

### 3.1 The inclusion-exclusion principle and the möbius function

The efficient calculation of the number of elements in a set that are coprime with a given integer $x$ is a classic problem. The most elegant solution employs the inclusion-exclusion principle, formalized through the **Möbius function**, $\mu(n)$. This function is defined for every positive integer $n$ as follows:

$$\mu(n) = \begin{cases} 1 & \text{if } n \text{ is square-free with an even number of distinct prime factors} \ -1 & \text{if } n \text{ is square-free with an odd number of distinct prime factors} \ 0 & \text{if } n \text{ has a squared prime factor} \end{cases}$$

An integer is called "square-free" if it is not divisible by any perfect square other than 1.

The theorem linking the Möbius function to our problem states that, given an integer $x$ and a multiset $S$ of integers, the number of elements in $S$ that are coprime with $x$ is given by:

$$\text{count\_coprime}(x, S) = \sum_{d \mid x, \mu(d) \neq 0} \mu(d) \cdot |{s \in S : d \mid s}|$$

This formula allows us to calculate the coprimality degree of an element without having to test every individual pair. Instead of $O(n)$ gcd operations, we can perform the calculation based on the divisors of $x$.

### 3.2 Concrete example

Suppose we want to calculate the number of elements coprime with $x = 6$ in a multiset $S$ where the counts of multiples are already known: $|S_1|=10, |S_2|=5, |S_3|=3, |S_6|=1$.

The square-free divisors of 6 are ${1, 2, 3, 6}$.

The Möbius function values are: $\mu(1)=1, \mu(2)=-1, \mu(3)=-1, \mu(6)=1$.

Applying the formula:

$$\text{count\_coprime}(6, S) = \mu(1)|S_1| + \mu(2)|S_2| + \mu(3)|S_3| + \mu(6)|S_6|$$

$$\text{count\_coprime}(6, S) = (1 \cdot 10) + (-1 \cdot 5) + (-1 \cdot 3) + (1 \cdot 1) = 10 - 5 - 3 + 1 = 3$$

### 3.3 Implementation of the linear sieve

To use the previous formula, we need the values of the Möbius function and the prime factors of integers up to $m$. A **linear sieve** is the ideal tool for this precomputation in $O(m)$ time.

```cpp
struct NumberTheoryEngine {
  static constexpr size_t LIMIT = 1000001;
  array<int, LIMIT> minimal_prime;
  array<int, LIMIT> moebius;

  NumberTheoryEngine() {
    iota(minimal_prime.begin(), minimal_prime.end(), 0);
    fill(moebius.begin(), moebius.end(), 0);
    moebius[1] = 1;

    vector<int> prime_list;
    prime_list.reserve(80000); // Approximate prime count

    for (size_t i = 2; i < LIMIT; ++i) {
      if (minimal_prime[i] == static_cast<int>(i)) {
        prime_list.push_back(i);
        moebius[i] = -1;
      }

      for (int prime : prime_list) {
        if (prime > minimal_prime[i] || 
            static_cast<ll>(i) * prime >= static_cast<ll>(LIMIT))
          break;
        minimal_prime[i * prime] = prime;
        moebius[i * prime] = (prime == minimal_prime[i]) ? 0 : -moebius[i];
      }
    }
  }
};
```

This linear sieve implementation efficiently computes both the smallest prime factor and Möbius function values for all numbers up to the limit, enabling fast factorization and coprimality calculations.

---

## 4. A stratified algorithmic strategy

The algorithm adopts a multi-phase approach designed to solve the problem as efficiently as possible.

### Phase 0: Preprocessing and data structures

The first step consists of preparing the data structures that will support subsequent phases:

1. **Linear sieve execution**: Computing Möbius values and prime factorizations
2. **Frequency and divisibility counting**: Building frequency arrays for efficient lookups
3. **Value compression**: Identifying unique values and storing their properties

```cpp
class ValueCompressor {
public:
  struct CompressedValue {
    int original;
    int compressed_id;
    vector<int> occurrence_indices;
    vector<int> squarefree_factors;
  };

private:
  unordered_map<int, size_t> compression_map;
  vector<CompressedValue> compressed_data;

public:
  void compress(span<const int> input_sequence) {
    compression_map.clear();
    compressed_data.clear();
    compression_map.reserve(input_sequence.size());

    for (size_t idx = 0; idx < input_sequence.size(); ++idx) {
      int value = input_sequence[idx];
      
      auto [iter, inserted] = compression_map.try_emplace(value, compressed_data.size());
      if (inserted) {
        compressed_data.push_back({
          .original = value,
          .compressed_id = static_cast<int>(compressed_data.size() - 1),
          .occurrence_indices = {static_cast<int>(idx + 1)}, // 1-indexed
          .squarefree_factors = NT_ENGINE.factorize_squarefree(value)
        });
      } else {
        compressed_data[iter->second].occurrence_indices.push_back(static_cast<int>(idx + 1));
      }
    }
  }
};
```

### Phase 1: Handling unit values

The value 1 is exceptional since $\gcd(1, k) = 1$ for any $k$. Its presence simplifies the search significantly:

```cpp
struct UnitValueStrategy {
  static auto execute(span<const int> unit_indices, span<const int> sequence) -> MaybeSolution {
    size_t unit_count = unit_indices.size();

    if (unit_count >= 4) {
      return Quadruple{unit_indices[0], unit_indices[1], unit_indices[2], unit_indices[3]};
    }

    if (unit_count == 3) {
      for (size_t i = 1; i < sequence.size(); ++i) {
        if (sequence[i] != 1) {
          return Quadruple{unit_indices[0], unit_indices[1], unit_indices[2], static_cast<int>(i)};
        }
      }
      return nullopt;
    }

    if (unit_count == 2) {
      vector<int> non_units;
      for (size_t i = 1; i < sequence.size() && non_units.size() < 2; ++i) {
        if (sequence[i] != 1) {
          non_units.push_back(static_cast<int>(i));
        }
      }
      if (non_units.size() >= 2) {
        return Quadruple{unit_indices[0], non_units[0], unit_indices[1], non_units[1]};
      }
    }

    return nullopt;
  }
};
```

### Phase 2: Exploiting duplicate values

If a value $v > 1$ appears multiple times and has sufficient coprimes, the solution becomes straightforward:

```cpp
// Phase 2: Duplicate value exploitation
for (size_t id = 0; id < compressor.unique_count(); ++id) {
  if (cached_occurrences[id].size() >= 2 && cached_original_values[id] != 1) {
    int coprime_candidates = cached_coprime_degrees[id];

    if (coprime_candidates >= 2) {
      vector<int> partners;
      for (int i = 1; i <= spec.element_count && partners.size() < 2; ++i) {
        if (gcd(cached_original_values[id], spec.sequence[i]) == 1) {
          partners.push_back(i);
        }
      }

      if (partners.size() >= 2) {
        output_solution({cached_occurrences[id][0], partners[0], 
                        cached_occurrences[id][1], partners[1]});
        return;
      }
    }
  }
}
```

### Phase 3: Single unit case

When exactly one '1' exists in the array, it guarantees one coprime pair. The problem reduces to finding a second coprime pair among the remaining elements:

```cpp
auto handle_single_unit_case(int unit_index) -> MaybeSolution {
  // Find any coprime pair among non-unit values
  for (size_t id = 0; id < compressor.unique_count(); ++id) {
    if (cached_original_values[id] == 1) continue;

    int non_unit_coprimes = cached_coprime_degrees[id] - 1; // Exclude the unit
    if (non_unit_coprimes < 1) continue;

    int first_index = cached_occurrences[id][0];

    for (int partner = 1; partner <= spec.element_count; ++partner) {
      if (partner == unit_index || partner == first_index) continue;

      if (gcd(cached_original_values[id], spec.sequence[partner]) == 1) {
        for (int fourth = 1; fourth <= spec.element_count; ++fourth) {
          if (fourth != unit_index && fourth != first_index && fourth != partner) {
            return Quadruple{first_index, partner, unit_index, fourth};
          }
        }
      }
    }
  }
  return nullopt;
}
```

### Phase 4: Degree-based heuristic search

When special cases fail, we resort to a more sophisticated search based on coprimality degrees.

#### 4.1 Prioritizing leaf vertices

Vertices with degree 1 (leaves in the graph) are critical: they have only one possible partner. If we don't pair them immediately, they might block future solutions:

```cpp
// Handle leaf vertices (degree 1)
for (size_t value_id = 0; value_id < compressor.unique_count(); ++value_id) {
  if (cached_coprime_degrees[value_id] == 1) {
    int leaf_index = cached_occurrences[value_id][0];

    for (int partner = 1; partner <= spec.element_count; ++partner) {
      if (partner != leaf_index && 
          gcd(cached_original_values[value_id], spec.sequence[partner]) == 1) {
        
        // Temporarily remove both from consideration
        analyzer->modify_element_presence(cached_squarefree_factors[value_id], -1);
        analyzer->modify_element_presence(cached_squarefree_factors[partner_id], -1);

        auto [third, fourth] = filtered_coprime_search(leaf_index, partner);

        if (third != -1) {
          return Quadruple{leaf_index, partner, third, fourth};
        }

        // Restore
        analyzer->modify_element_presence(cached_squarefree_factors[value_id], +1);
        analyzer->modify_element_presence(cached_squarefree_factors[partner_id], +1);

        // Leaf can't form solution - no solution exists
        return nullopt;
      }
    }
  }
}
```

#### 4.2 Bounded search with degree ordering

For remaining elements, we sort by increasing degree and apply bounded search:

```cpp
// Build list of ALL indices sorted by degree of their VALUE
vector<int> sorted_indices;
sorted_indices.reserve(spec.element_count);

for (size_t value_id = 0; value_id < compressor.unique_count(); ++value_id) {
  if (cached_coprime_degrees[value_id] >= 1) {
    for (int idx : cached_occurrences[value_id]) {
      sorted_indices.push_back(idx);
    }
  }
}

// Sort by degree of the value, then by index
sort(sorted_indices.begin(), sorted_indices.end(), [this](int a, int b) {
  int id_a = sequence_to_compressed_id[a];
  int id_b = sequence_to_compressed_id[b];
  if (cached_coprime_degrees[id_a] != cached_coprime_degrees[id_b]) {
    return cached_coprime_degrees[id_a] < cached_coprime_degrees[id_b];
  }
  return a < b;
});

// Try combinations with bounded search
constexpr int SEARCH_WIDTH = 30;

for (int primary_index : sorted_indices) {
  vector<int> candidates;
  candidates.reserve(SEARCH_WIDTH);

  for (int partner = 1; partner <= spec.element_count && 
       static_cast<int>(candidates.size()) < SEARCH_WIDTH; ++partner) {
    if (partner != primary_index && 
        gcd(spec.sequence[primary_index], spec.sequence[partner]) == 1) {
      candidates.push_back(partner);
    }
  }

  for (int secondary_index : candidates) {
    // Try this pair and search for remaining coprime pair
    // ... implementation details ...
  }
}
```

---

## 5. Modern C++ implementation choices

The implementation leverages several modern C++ features and idioms for improved performance and readability.

### 5.1 Structured bindings and auto declarations

Modern C++ structured bindings enhance code readability:

```cpp
auto [iter, inserted] = compression_map.try_emplace(value, compressed_data.size());
auto [third, fourth] = filtered_coprime_search(leaf_index, partner);
```

### 5.2 std::span For zero-copy views

Using `std::span` (C++20) allows passing array views without copying:

```cpp
void compress(span<const int> input_sequence) {
  // Process without copying the input data
}
```

### 5.3 Designated initializers

C++20 designated initializers improve struct initialization clarity:

```cpp
compressed_data.push_back({
  .original = value,
  .compressed_id = static_cast<int>(compressed_data.size() - 1),
  .occurrence_indices = {static_cast<int>(idx + 1)},
  .squarefree_factors = NT_ENGINE.factorize_squarefree(value)
});
```

### 5.4 Constexpr and compile-time optimization

Using `constexpr` enables compile-time computation where possible:

```cpp
static constexpr size_t LIMIT = 1000001;
constexpr int SEARCH_WIDTH = 30;
```

### 5.5 Memory management and cache optimization

Strategic use of `reserve()` prevents vector reallocations:

```cpp
prime_list.reserve(80000); // Approximate prime count for better cache locality
candidates.reserve(SEARCH_WIDTH);
```

---

## 6. Complexity Analysis

### 6.1 Time complexity

Analyzing each component:

1. **Sieve Preprocessing**: $O(m)$ using linear sieve
2. **Square-free Divisor Computation**: $O(U \times 2^{\omega(\text{max})})$ where $\omega(n)$ is the number of distinct primes
3. **Divisibility Counting**: $O(m \log m)$
4. **Phases 1-3**: $O(n)$ each
5. **Phase 4**: $O(n \times \min(n, 30)) = O(n \times 30)$ with bounded search

**Total Complexity**: $O(m \log m + n \times 30 + U \times 2^{\omega(\text{max})})$

In practice, for the problem constraints ($m \leq 10^6$, $n \leq 2 \times 10^5$), the algorithm operates in near-linear time for most inputs.

### 6.2 Space complexity

The main data structures require:

- Sieve: $O(m)$
- Square-free divisors: $O(U \times d(\text{max}))$
- Divisibility counts: $O(m)$
- Auxiliary structures: $O(n)$

**Total Space**: $O(m + n + U \times d(\text{max}))$

---

## 7. Performance considerations and optimizations

### 7.1 Incremental updates

Instead of recalculating degrees after each element "removal," we update incrementally:

```cpp
void modify_element_presence(const vector<int>& squarefree_factors, int delta) {
  for (int divisor : squarefree_factors) {
    divisor_multiplicities[divisor] += delta;
  }
}
```

This reduces the cost of each update from $O(m)$ to $O(d(\text{value}))$, typically very small.

### 7.2 Precomputation and caching

All values depending only on unique values are computed once:

```cpp
vector<int> cached_coprime_degrees;    // Precomputed coprime degrees per unique value
vector<int> cached_original_values;    // Original values per compressed ID
vector<vector<int>> cached_occurrences; // Occurrence indices per compressed ID
```

### 7.3 Early termination

Each phase terminates as soon as it finds a solution, avoiding unnecessary computations:

```cpp
void solve() {
  if (handle_unit_values()) return;
  if (exploit_duplicates()) return;
  if (handle_single_unit()) return;
  if (process_leaf_vertices()) return;
  if (general_search()) return;
  
  cout << "0\n";  // No solution
}
```

---

## 8. Conclusion

The resolution of the "Sea, You & copriMe" problem constitutes an excellent example of how the synergistic application of concepts from different areas of mathematics and computer science can lead to efficient solutions for computationally challenging problems. The pillars of this solution have been:

1. **Problem Abstraction**: Translating the problem into a graph model provided the conceptual framework for reasoning about its structure.
    
2. **Power of Number Theory**: The employment of the Möbius function and inclusion-exclusion principle proved fundamental for performing otherwise prohibitive calculations.
    
3. **Stratified Algorithm Design**: Prioritized handling of special and simple cases allowed avoiding complex computations for a vast class of inputs.
    
4. **Effective Heuristics**: The use of heuristics, such as priority to low-degree vertices and bounded search, drastically reduced the search space while maintaining solution correctness.
    
5. **Modern C++ Implementation**: Leveraging modern C++ features like structured bindings, `std::span`, and designated initializers improved both performance and code readability.
    

This approach demonstrates that, even in the modern context, mastery of classical algorithms and fundamental mathematical structures remains an irreplaceable and highly powerful tool for software engineering and complex problem solving. The combination of theoretical insights with practical implementation considerations showcases the elegance that can be achieved when mathematical rigor meets engineering pragmatism.