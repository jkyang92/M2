TEST ///
  -- test the following:
  --  gradings:
  --    standard grading
  --    ZZ^1 grading
  --    ZZ^r grading
  --  rings:
  --    polynomial ring
  --    exterior algebra
  --    quotient of a poly ring
  --    quotient of an exterior algebra
  --    Weyl algebra (?? probably not: what does this mean)
  --  coeff rings:
  --    a basic field
  --    a poly ring
  --    a quotient of a polynomial ring
  --  truncations:
  --    truncate(D, S)
  --    truncate(D, S^1)
  --    truncate(D, ideal)
  --    truncate(D, graded free module)
  --    truncate(D, coker module)
  --    truncate(D, image module)
  --    truncate(D, subquotient module)
  --    truncate(D, Matrix)
///

TEST /// -- Singly generated case
  R = QQ[a..d]
  I = ideal(b*c-a*d,b^2-a*c,d^10)
  assert(truncate(2,I) == I)
  assert(truncate(3,I) == intersect((ideal vars R)^3, I))

  R = ZZ/101[a..d, Degrees => {1,2,3,4}]
  assert(truncate(2, R^1) == image matrix {{a^2, a*b, a*c, a*d, b, c, d}})
  assert(truncate(4, ideal"a3,b3") == ideal(a^4,a^3*b,a^3*c,a^3*d,b^3))

  R = QQ[a..d, Degrees => {3,4,7,9}]
  I = ideal(a^3,b^4,c^6)
  assert(truncate(12, I) == ideal(a^4,a^3*b,a^3*c,a^3*d,b^4,c^6))

  R = ZZ[a,b,c]
  I = ideal(15*a,21*b,19*c)
  assert(trim truncate(2, I) == ideal(19*c^2,b*c,a*c,21*b^2,3*a*b,15*a^2))
///

TEST ///
  A = ZZ/101[a..d, Degrees => {4:0}]
  assert(truncate(2, A) == image matrix{{0_A}})

  B = ZZ/101[a,b,c,d,e, Degrees=>{3:{1,0}, 2:{0,1}}]
  assert(truncate({1,2}, B) == ideal{c*e^2, b*e^2, a*e^2, c*d*e, b*d*e, a*d*e, c*d^2, b*d^2, a*d^2})
///

TEST ///
  R = ZZ/101[x_0,x_1,y_0,y_1,y_2,Degrees=>{2:{1,1,0},3:{1,0,1}}];
  I = ideal random(R^1,R^{6:{-6,-2,-4},4:{-6,-3,-3}});
  J = truncate({6,2,3},I);
  assert(J == I)
///

TEST ///
  E = ZZ/101[a..f, SkewCommutative => {0,2,4}, Degrees => {2:{3,1},2:{4,-2},2:{1,3}}]
  elapsedTime truncate({7,1},E)

  debug needsPackage "Truncations"
  elapsedTime numgens truncationMonomials({7,1},E) == 28

  A = transpose matrix degrees E
  P = truncationPolyhedron(A,{7,1}, Exterior => (options E).SkewCommutative)
  P1 = truncationPolyhedron(A,{7,1})

  needsPackage "Polyhedra"
  elapsedTime halfspaces P
  elapsedTime # hilbertBasis cone P == 1321
  elapsedTime # hilbertBasis cone P1 == 1851
///

TEST /// -- of checkOrMakeDegreeList
  debug needsPackage "Truncations"
  assert(checkOrMakeDegreeList(3, 1) == {{3}})
  assert(checkOrMakeDegreeList({3}, 1) == {{3}})
  assert try checkOrMakeDegreeList(3, 2) else true
  assert(checkOrMakeDegreeList({1,2}, 2) === {{1,2}})
  assert try checkOrMakeDegreeList({1,2,3}, 2) else true
  assert(checkOrMakeDegreeList({{1,0},{3,-5}}, 2) === {{1,0},{3,-5}})
  assert try checkOrMakeDegreeList({{1,0},{3,-5},{3,4,5}}, 2) else true
  assert try checkOrMakeDegreeList({{1,0},{3,-5},3}, 2) else true
///

TEST /// -- of truncateImplemented
  debug needsPackage "Truncations"
  assert truncateImplemented(ZZ/101[a..d])
  assert truncateImplemented(ZZ/101[a..d, Degrees => {1,1,-1,-1}])
  assert truncateImplemented(ZZ/101[a..d, Degrees => {2:{3,1},2:{-4,2}}])

  assert truncateImplemented(QQ[a..d, SkewCommutative=>true])
  assert truncateImplemented(QQ[a..d, SkewCommutative=>{0,3}])

  assert truncateImplemented(ZZ[a..d])
  assert truncateImplemented(ZZ[a..d, Degrees => {1,1,-1,-1}])
  assert truncateImplemented(ZZ[a..d, Degrees => {2:{3,1},2:{-4,2}}])

  assert truncateImplemented(ZZ[a..d, SkewCommutative=>true])
  assert truncateImplemented(ZZ[a..d, SkewCommutative=>{0,3}])

  assert truncateImplemented(ZZ/101[a..d]/(a*d-b*c))
  assert truncateImplemented(ZZ/101[a..d, Degrees => {1,1,-1,-1}]/(a*d-b*c))
  assert truncateImplemented(ZZ/101[a..d, Degrees => {2:{3,1},2:{-4,2}}]/(a*d-b*c))

  assert truncateImplemented(QQ[a..d, SkewCommutative=>true]/(a*d-b*c))
  assert truncateImplemented(QQ[a..d, SkewCommutative=>{0,3}]/(a*d-b*c))

  assert truncateImplemented(ZZ[a..d]/(3*a*d-b*c))
  assert truncateImplemented(ZZ[a..d, Degrees => {1,1,-1,-1}]/(a*d-b*c))
  assert truncateImplemented(ZZ[a..d, Degrees => {2:{3,1},2:{-4,2}}]/(a*d-b*c))

  assert truncateImplemented(ZZ[a..d, SkewCommutative=>true]/(a*d-b*c))
  assert truncateImplemented(ZZ[a..d, SkewCommutative=>{0,3}]/(a*d-b*c))

  -- testing towers of rings
  assert truncateImplemented(R1 = ZZ[a,b,c])
  assert truncateImplemented(R2 = R1/(3*a,5*b))
  assert truncateImplemented(R3 = R2[s,t])
  assert truncateImplemented(R4 = QQ[x,y,z])

  assert truncateImplemented(E1 = ZZ[a,b,c, SkewCommutative => true])
  assert truncateImplemented(E2 = E1/(a*b))
  assert truncateImplemented(E3 = ZZ[d,e,f, SkewCommutative => {0,2}])
  assert((options E3).SkewCommutative == {0,2})
  assert truncateImplemented(E1[x,y])
  assert truncateImplemented(E1[x,y, SkewCommutative => true])
///

TEST ///
  debug needsPackage "Truncations"
  S = ZZ/101[a,b,c, Degrees =>{5,6,7}]
  truncationMonomials({10}, S)
  assert(truncationMonomials({{9},{11}}, S) == truncationMonomials({9},S))

  E = ZZ/101[a, b, c, SkewCommutative=>true]
  truncationMonomials({2}, E)

  E = ZZ/101[a,b,c, SkewCommutative=>{0,1}]
  truncationMonomials({2}, E) -- FAILS: needs a monomial ideal

  use S
  assert(truncationMonomials({12},S) == ideal"a3,a2b,b2,ac,bc,c2")
  R = S/(a*c-2*b^2)
  assert(truncationMonomials({12},R) == ideal"a3,a2b,ac,bc,c2")
///

TEST /// -- test of truncations in singly graded poly ring case
  S = ZZ/101[a..d]
  I = monomialCurveIdeal(S, {1,3,4})
  assert(truncate(2, S) == (ideal vars S)^2)
  assert(truncate(2, S^1) == image gens (ideal vars S)^2)
  elapsedTime truncate(25, S^1);
  -- getting the map from truncate(d,F) --> F
  F = S^{-1} ++ S^{2}
  truncF = truncate(2, F)
  truncF2 = image map(F, truncF, gens truncF)
  truncF === truncF2

  -- test truncation of an ideal
  -- this assumes (tests) that truncation of an ideal is minimally generated.
  truncI = trim((ideal vars S)^2 * I_0 + (ideal vars S) * ideal(I_1, I_2, I_3))
  assert(truncate(4, I) == truncI)
  assert(numgens truncate(4, I) == 18)

  -- test of truncation of modules
  -- 1. coker module
  M = Ext^2(comodule I, S)
  assert not M.?generators
  assert(truncate(-3, M) == M)
  assert(truncate(-4, M) == M)
  truncM = truncate(-2, M)
  assert(truncM == ideal(a,b,c,d) * M)
  -- 2. image module
  -- 3. subquotient module
  C = res I
  E = trim((ker transpose C.dd_3)/(image transpose C.dd_2))
  truncate(-3, E) == E
  truncate(-4, E) == E
  truncE = truncate(-2, E)
  assert(truncE == ideal(a,b,c,d) * E)
  presentation truncM
  presentation truncE

  -- check functoriality:
  assert(0 == truncate(3, C.dd_1) * truncate(3, C.dd_2))
  assert(0 == truncate(3, C.dd_2) * truncate(3, C.dd_3))

  -- how to get the map: truncM == truncate(-2,M) --> M ??
  phi = map(M, truncM, gens truncM)
  assert(image phi == truncM)

  F = truncate(-2, target presentation M)
  G = truncate(-2, source presentation M)
  assert(F == target truncate(-2, presentation M))
  assert(G == source truncate(-2, presentation M))
///

TEST ///
  S = ZZ/101[a,b, Degrees =>{{0,1},{1,0}}]
  M = S^{-{5,2}, -{2,3}}
  D = {4,3}
  assert(truncate(D,S) == image matrix{{a^3*b^4}})
  assert(truncate(D,S) == truncate({D},S))

  E = {{4,3},{3,4}}
  assert(truncate(E,S) == image matrix{{a^3*b^4, a^4*b^3}})

  assert(truncate(D, M) == image map(M,, matrix {{a, 0}, {0, b^2}}))
///

TEST ///
  S = ZZ/101[a,b,c,d,e,Degrees=>{3,4,5,6,7}]

  assert(
      sort gens truncate({8},S)
      ==
      sort gens ideal(a*c,b^2,a*d,b*c,a^3,a*e,b*d,c^2,a^2*b,b*e,c*d,c*e,d^2,d*e,e^2)
      )

  truncate({8},S^{-4})
  truncate({8},S^{3})
  truncate({8},S^{-4,-5,-3})
  truncate(8,S^{-4,-5,-3})
  phi = random(S^{-1,-2,-3}, S^{-1,-2,-3,-4,-8})
  psi = truncate({8}, phi)
  assert(isHomogeneous psi)
///

TEST ///
  d = {5,6}
  D = {d,reverse d}

  kk = ZZ/101
  R = kk[a,b,c,Degrees =>{2:{3,4},{7,5}}]
  truncate({5,6},R)
  truncate({6,5},R)

  J1 = truncate(D, R)
  J1 = truncate(D, R^1)
  truncate(D, ideal(a,b,c))

  A = R/(a^2-b^2, c^3)
  truncate(D, A)
  truncate(d, R)
  M = module ideal(a,b,c)
  truncate(d, ideal(a,b,c))
  truncate(D, ideal(a,b,c))
  p = presentation M

  truncate(D, presentation M)
  truncate(D, source presentation M)
  truncate(D, target presentation M)
///

TEST /// -- Toric variety tests
  needsPackage "NormalToricVarieties"
  V = smoothFanoToricVariety(3,5)
  rays V
  max V
  S = ring V
  A = transpose matrix degrees S
  truncate({1,1,1}, S)
  basis({1,1,1}, S)
  C = posHull A
  C2 = dualCone C
  rays C2
///

end--

restart
check "Truncations"
