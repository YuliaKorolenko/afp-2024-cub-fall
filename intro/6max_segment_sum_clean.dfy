
// Implement a method MaxSegSum which finds the maximum sum of a subsequent segment [l..r] of a given array.

function Sum(a: seq<int>, s: int, t: int): int
  requires 0 <= s <= t <= |a|
{
  if s == t then 0 else Sum(a, s, t-1) + a[t-1]
}

method MaxSegSum(a: seq<int>) returns (k: int, m: int)
  ensures 0 <= k <= m <= |a|
  ensures forall p,q :: 0 <= p <= q <= |a| ==> Sum(a, p, q) <= Sum(a, k, m)
{
  k, m := 0, 0;
  var s := 0;  
  var n := 0;
  var c, t := 0, 0;  
  while n < |a|
     // add invariants
    invariant n < |a| + 1
    invariant 0 <= c <= n 
    invariant 0 <= k <= m < |a| + 1
    invariant s == Sum(a, k, m)
    invariant t == Sum(a, c, n)
    invariant forall j :: 0 <= c <= j < n ==> Sum(a, j, n) <= t 
    // invariant forall j :: 0 <= c <= j < n ==> Sum(a, c, j) <= t
    invariant forall p,q :: 0 <= p <= q < n ==> Sum(a, p, q) <= s
  {
    t, n := t + a[n], n + 1;
    if t < 0 {
      c, t := n, 0;
    } else if s < t {
      k, m, s := c, n, t;
    }
  }
}

// 1 2 3 8 1 0 6 7
// k = 0 m = 0 s = 0 c = 0 t = 1 
// n = 1