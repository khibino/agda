{-# OPTIONS --disable-positivity-check #-}

module univ where

open import Base
open import Nat

import Logic.ChainReasoning
module Chain
  {A : Set}( _==_ : A -> A -> Set)
  (refl : {x : A} -> x == x)
  (trans : {x y z : A} -> x == y -> y == z -> x == z) =
  Logic.ChainReasoning.Mono.Homogenous _==_ (\x -> refl) (\x y z -> trans)

-- mutual inductive recursive definition of S and the functions _=S_, El, eq,
-- and all the proofs on these functions

mutual

  infix 40 _==_ _=S_
  infixr 80 _<<_

  data S : Set where
    nat   : S
    pi    : (A : S)(F : El A -> S) -> Map (El A) _==_ S _=S_ F -> S
    sigma : (A : S)(F : El A -> S) -> Map (El A) _==_ S _=S_ F -> S

  _=S'_ : rel S
  nat          =S' nat          = True
  nat          =S' pi _ _ _     = False
  pi _ _ _     =S' nat          = False
  nat          =S' sigma _ _ _  = False
  sigma _ _ _  =S' nat          = False
  sigma _ _ _  =S' pi _ _ _     = False
  pi _ _ _     =S' sigma _ _ _  = False
  pi A F pF    =S' pi B G pG    =
      (B =S A) * \ B=A -> (x : El A) -> F x =S G (B=A << x)
  sigma A F pF =S' sigma B G pG =
      (A =S B) * \A=B -> (x : El B) -> F (A=B << x) =S G x

  data _=S_ (A B : S) : Set where
    eqS : A =S' B -> A =S B

  El' : S -> Set
  El' nat = Nat
  El' (pi A F pF) = 
    ((x : El A) -> El (F x)) * \f ->
    {x y : El A}(x=y : x == y) -> f x == pF x=y << f y
  El' (sigma A F pF) =
    El A * \x -> El (F x)

  data El (A : S) : Set where
    el : El' A -> El A

  _=='_ : {A : S} -> rel (El A)
  _=='_ {nat} (el x) (el y) = x =N y
  _=='_ {pi A F pF} (el < f , pf >) (el < g , pg >) =
        (x : El A) -> f x == g x
  _=='_ {sigma A F pF} (el < x , Fx >) (el < y , Fy >) =
        x == y * \x=y -> Fx == pF x=y << Fy

  data _==_ {A : S}(x y : El A) : Set where
    eq : x ==' y -> x == y

  _<<_ : {A B : S} -> A =S B -> El B -> El A
  _<<_ {nat        }{pi _ _ _   } (eqS ()) _
  _<<_ {nat        }{sigma _ _ _} (eqS ()) _
  _<<_ {pi _ _ _   }{nat        } (eqS ()) _
  _<<_ {pi _ _ _   }{sigma _ _ _} (eqS ()) _
  _<<_ {sigma _ _ _}{nat        } (eqS ()) _
  _<<_ {sigma _ _ _}{pi _ _ _   } (eqS ()) _
  _<<_ {nat        }{nat        } p x = x
  _<<_ {pi A F pF  }{pi B G pG  } (eqS < B=A , F=G >) (el < g , pg >) =
    el < f , (\{x}{y} -> pf x y) >
    where
      f : (x : El A) -> El (F x)
      f x = F=G x << g (B=A << x)

      pf : (x y : El A)(x=y : x == y) -> f x == pF x=y << f y
      pf x y x=y =
        chain> F=G x << g (B=A << x)
           === F=G x << _      << g (B=A << y)  by p<< _ (pg (p<< B=A x=y))
           === pF x=y << F=G y << g (B=A << y)  by pfi2 _ _ _ _ _
        where
          open module C = Chain _==_ (ref {F x}) (trans {F x})
  _<<_ {sigma A F pF}{sigma B G pG} (eqS < A=B , F=G >) (el < y , Gy >) =
    el < A=B << y , F=G y << Gy >

  p<< : {A B : S}(A=B : A =S B) -> Map (El B) _==_ (El A) _==_ (_<<_ A=B)
  p<< {nat}{nat} _ x=y = x=y
  p<< {pi A F pF} {pi B G pG} (eqS < B=A , F=G >)
        {el < f , pf >} {el < g , pg >} (eq f=g) = eq cf=cg
    where
      cf=cg : (x : El A) -> F=G x << f (B=A << x) == F=G x << g (B=A << x)
      cf=cg x = p<< (F=G x) (f=g (B=A << x))

  p<< {sigma A F pF}{sigma B G pG}(eqS < A=B , F=G >)
      {el < x , Gx >}{el < y , Gy >} (eq < x=y , Gx=Gy >) =
      eq < cx=cy , cGx=cGy >
    where
      cx=cy : A=B << x == A=B << y
      cx=cy = p<< A=B x=y

      cGx=cGy : F=G x << Gx == pF cx=cy << F=G y << Gy
      cGx=cGy =
        chain> F=G x    << Gx
           === F=G x    << pG x=y << Gy  by p<< (F=G x) Gx=Gy
           === pF cx=cy << F=G y  << Gy  by pfi2 _ _ _ _ Gy
        where
          open module C = Chain _==_ (ref {F (A=B << x)}) (trans {F (A=B << x)})

  p<< {nat        }{pi _ _ _   } (eqS ()) _
  p<< {nat        }{sigma _ _ _} (eqS ()) _
  p<< {pi _ _ _   }{nat        } (eqS ()) _
  p<< {pi _ _ _   }{sigma _ _ _} (eqS ()) _
  p<< {sigma _ _ _}{nat        } (eqS ()) _
  p<< {sigma _ _ _}{pi _ _ _   } (eqS ()) _

  refS : Refl _=S_
  refS {nat}          = eqS T
  refS {pi A F pF}    = eqS < refS , (\x -> symS (pF (ref<< x))) >
  refS {sigma A F pF} = eqS < refS , (\x -> pF (ref<< x)) >

  transS : Trans _=S_
  transS {nat         }{nat         }{pi _ _ _    } _ (eqS ())
  transS {nat         }{nat         }{sigma _ _ _ } _ (eqS ())
  transS {nat         }{pi _ _ _    }               (eqS ()) _
  transS {nat         }{sigma _ _ _ }               (eqS ()) _
  transS {pi _ _ _    }{nat         }               (eqS ()) _
  transS {pi _ _ _    }{pi _ _ _    }{nat         } _ (eqS ())
  transS {pi _ _ _    }{pi _ _ _    }{sigma _ _ _ } _ (eqS ())
  transS {pi _ _ _    }{sigma _ _ _ }               (eqS ()) _
  transS {sigma _ _ _ }{nat         }               (eqS ()) _
  transS {sigma _ _ _ }{pi _ _ _    }               (eqS ()) _
  transS {sigma _ _ _ }{sigma _ _ _ }{nat         } _ (eqS ())
  transS {sigma _ _ _ }{sigma _ _ _ }{pi _ _ _    } _ (eqS ())
  transS {nat}{nat}{nat} p q = p
  transS {pi A F pF}{pi B G pG}{pi C H pH}
         (eqS < B=A , F=G >) (eqS < C=B , G=H >) = eqS < C=A , F=H >
    where
      open module C = Chain _=S_ refS transS
      C=A = transS C=B B=A
      F=H : (x : El A) -> F x =S H (C=A << x)
      F=H x =
        chain> F x
           === G (B=A << x)           by F=G x
           === H (C=B << B=A << x)    by G=H (B=A << x)
           === H (C=A << x)           by pH (sym (trans<< C=B B=A x))
  transS {sigma A F pF}{sigma B G pG}{sigma C H pH}
         (eqS < A=B , F=G >)(eqS < B=C , G=H >) = eqS < A=C , F=H >
    where
      open module C = Chain _=S_ refS transS
      A=C = transS A=B B=C
      F=H : (x : El C) -> F (A=C << x) =S H x
      F=H x =
        chain> F (A=C << x)
           === F (A=B << B=C << x) by pF (trans<< A=B B=C x)
           === G (B=C << x)        by F=G (B=C << x)
           === H x                 by G=H x

  symS : Sym _=S_
  symS {nat        }{pi _ _ _   } (eqS ())
  symS {nat        }{sigma _ _ _} (eqS ())
  symS {pi _ _ _   }{nat        } (eqS ())
  symS {pi _ _ _   }{sigma _ _ _} (eqS ())
  symS {sigma _ _ _}{nat        } (eqS ())
  symS {sigma _ _ _}{pi _ _ _   } (eqS ())
  symS {nat}{nat} p                 = p
  symS {pi A F pF}{pi B G pG} (eqS < B=A , F=G >) = eqS < A=B , G=F >
    where
      open module C = Chain _=S_ refS transS
      A=B = symS B=A
      G=F : (x : El B) -> G x =S F (A=B << x)
      G=F x = symS (
        chain> F (A=B << x)
           === G (B=A << A=B << x) by F=G (A=B << x)
           === G (refS << x)       by pG (casttrans B=A A=B refS x)
           === G x                 by pG (ref<< x)
        )
  symS {sigma A F pF}{sigma B G pG}(eqS < A=B , F=G >) = eqS < B=A , G=F >
    where
      open module C = Chain _=S_ refS transS
      B=A = symS A=B
      G=F : (x : El A) -> G (B=A << x) =S F x
      G=F x =
        chain> G (B=A << x)
           === F (A=B << B=A << x) by symS (F=G _)
           === F (refS << x)       by pF (casttrans _ _ _ x)
           === F x                 by pF (castref _ x)

  pfi : {A B : S}(p q : A =S B)(x : El B) -> p << x == q << x
  pfi {nat        }{pi _ _ _   } (eqS ()) _ _
  pfi {nat        }{sigma _ _ _} (eqS ()) _ _
  pfi {pi _ _ _   }{nat        } (eqS ()) _ _
  pfi {pi _ _ _   }{sigma _ _ _} (eqS ()) _ _
  pfi {sigma _ _ _}{nat        } (eqS ()) _ _
  pfi {sigma _ _ _}{pi _ _ _   } (eqS ()) _ _
  pfi {nat}{nat} _ _ x = ref
  pfi {pi A F pF}{pi B G pG} (eqS < B=A1 , F=G1 >) (eqS < B=A2 , F=G2 >)
      (el < g , pg >) = eq g1=g2
    where
      g1=g2 : (x : El A) -> F=G1 x << g (B=A1 << x)
                         == F=G2 x << g (B=A2 << x)
      g1=g2 x =
        chain> F=G1 x      << g (B=A1 << x)
           === F=G1 x << _ << g (B=A2 << x) by p<< _ (pg (pfi B=A1 B=A2 x))
           === F=G2 x      << g (B=A2 << x) by casttrans _ _ _ _
        where
          open module C = Chain _==_ (ref {F x}) (trans {F x})
  pfi {sigma A F pF}{sigma B G pG} (eqS < A=B1 , F=G1 >) (eqS < A=B2 , F=G2 >)
      (el < y , Gy >) = eq < x1=x2 , Fx1=Fx2 >
    where
      x1=x2 : A=B1 << y == A=B2 << y
      x1=x2 = pfi A=B1 A=B2 y

      Fx1=Fx2 : F=G1 y << Gy == pF x1=x2 << F=G2 y << Gy
      Fx1=Fx2 = sym (casttrans _ _ _ _)

  ref<< : {A : S}(x : El A) -> refS << x == x
  ref<< {nat}       x = ref
  ref<< {sigma A F pF} (el < x , Fx >) = eq < ref<< x , pfi _ _ Fx >
  ref<< {pi A F pF} (el < f , pf >) = eq rf=f
    where
      rf=f : (x : El A) -> _ << f (refS << x) == f x
      rf=f x =
        chain> _ << f (refS << x)
           === _ << pF (ref<< x) << f x by p<< _ (pf (ref<< x))
           === _ << f x                 by sym (trans<< _ _ (f x))
           === f x                      by castref _ _
        where open module C = Chain _==_ (ref {_}) (trans {_})

  trans<< : {A B C : S}(A=B : A =S B)(B=C : B =S C)(x : El C) ->
            transS A=B B=C << x == A=B << B=C << x
  trans<< {nat         }{nat         }{pi _ _ _    } _ (eqS ()) _
  trans<< {nat         }{nat         }{sigma _ _ _ } _ (eqS ()) _
  trans<< {nat         }{pi _ _ _    }               (eqS ()) _ _
  trans<< {nat         }{sigma _ _ _ }               (eqS ()) _ _
  trans<< {pi _ _ _    }{nat         }               (eqS ()) _ _
  trans<< {pi _ _ _    }{pi _ _ _    }{nat         } _ (eqS ()) _
  trans<< {pi _ _ _    }{pi _ _ _    }{sigma _ _ _ } _ (eqS ()) _
  trans<< {pi _ _ _    }{sigma _ _ _ }               (eqS ()) _ _
  trans<< {sigma _ _ _ }{nat         }               (eqS ()) _ _
  trans<< {sigma _ _ _ }{pi _ _ _    }               (eqS ()) _ _
  trans<< {sigma _ _ _ }{sigma _ _ _ }{nat         } _ (eqS ()) _
  trans<< {sigma _ _ _ }{sigma _ _ _ }{pi _ _ _    } _ (eqS ()) _
  trans<< {nat}{nat}{nat} _ _ _ = ref
  trans<< {pi A F pF}{pi B G pG}{pi C H pH}
          (eqS < B=A , F=G >)(eqS < C=B , G=H >)
          (el < h , ph >) = eq prf
    where
      C=A = transS C=B B=A
      prf : (x : El A) -> _
      prf x =
        chain> _ << h (C=A << x)
           === _ << _ << h (C=B << B=A << x)         by p<< _ (ph (trans<< _ _ x))
           === F=G x << G=H _ << h (C=B << B=A << x) by pfi2 _ _ _ _ _
        where open module C' = Chain _==_ (ref {F x}) (trans {F x})
  trans<< {sigma A F pF}{sigma B G pG}{sigma C H pH}
          (eqS < A=B , F=G >)(eqS < B=C , G=H >)
          (el < z , Hz >) = eq < trans<< A=B B=C z , prf >
    where
      prf =
        chain> _ << Hz
           === _ << Hz                   by pfi _ _ _
           === _ << _ << Hz              by trans<< _ _ _
           === _ << F=G _ << G=H z << Hz by trans<< _ _ _
        where open module C' = Chain _==_ (ref {_}) (trans {_})

  castref : {A : S}(p : A =S A)(x : El A) -> p << x == x
  castref A=A x =
    chain> A=A << x
       === refS << x  by pfi A=A refS x
       === x          by ref<< x
    where open module C = Chain _==_ (ref {_}) (trans {_})

  casttrans : {A B C : S}(A=B : A =S B)(B=C : B =S C)(A=C : A =S C)(x : El C) ->
               A=B << B=C << x == A=C << x
  casttrans A=B B=C A=C x =
    chain> A=B << B=C << x
       === _ << x     by sym (trans<< _ _ _)
       === A=C << x   by pfi _ _ _
    where open module C' = Chain _==_ (ref {_}) (trans {_})

  pfi2 : {A B1 B2 C : S}
         (A=B1 : A =S B1)(A=B2 : A =S B2)(B1=C : B1 =S C)(B2=C : B2 =S C)
         (x : El C) -> A=B1 << B1=C << x == A=B2 << B2=C << x
  pfi2 A=B1 A=B2 B1=C B2=C x =
    chain> A=B1 << B1=C << x
       === _ << x             by casttrans _ _ _ x
       === A=B2 << B2=C << x  by trans<< _ _ x
    where
      open module C = Chain _==_ (ref {_}) (trans {_})

  ref : {A:S} -> Refl {El A} _==_
  ref {nat}      {el n}             = eq (refN {n})
  ref {pi A F pF}{el < f , pf >}    = eq \x -> ref
  ref {sigma A F pF}{el < x , Fx >} = eq < ref , sym (castref _ _) >

  trans : {A:S} -> Trans {El A} _==_
  trans {nat}{el x}{el y}{el z} (eq p) (eq q) = eq (transN {x}{y}{z} p q)
  trans {pi A F pF}{el < f , pf >}{el < g , pg >}{el < h , ph >}
        (eq f=g)(eq g=h) = eq \x -> trans (f=g x) (g=h x)
  trans {sigma A F pF}{el < x , Fx >}{el < y , Fy >}{el < z , Fz >}
        (eq < x=y , Fx=Fy >)(eq < y=z , Fy=Fz >) =
        eq < x=z , Fx=Fz >
    where
      x=z   = trans x=y y=z
      Fx=Fz =
        chain> Fx
           === pF x=y << Fy           by Fx=Fy
           === pF x=y << pF y=z << Fz by p<< _ Fy=Fz
           === pF x=z << Fz           by casttrans _ _ _ _
        where open module C = Chain _==_ (ref {_}) (trans {_})

  sym : {A:S} -> Sym {El A} _==_
  sym {nat}{el x}{el y} (eq p)  = eq (symN {x}{y} p)
  sym {pi A F pF}{el < f , pf >}{el < g , pg >}
      (eq f=g) = eq \x -> sym (f=g x)
  sym {sigma A F pF}{el < x , Fx >}{el < y , Fy >}
      (eq < x=y , Fx=Fy >) = eq < y=x , Fy=Fx >
    where
      y=x = sym x=y
      Fy=Fx = sym (
        chain> pF y=x << Fx 
           === pF y=x << pF x=y << Fy by p<< (pF y=x) Fx=Fy
           === refS << Fy             by casttrans _ _ _ _
           === Fy                     by castref _ _
        )
        where open module C = Chain _==_ (ref {_}) (trans {_})

