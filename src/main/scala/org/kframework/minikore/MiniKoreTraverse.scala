package org.kframework.minikore

import org.kframework.minikore.{MiniKoreInterface => i}

/**
  * Created by daejunpark on 1/31/17.
  */
object MiniKoreTraverse {

//  def fold[P1 <: i.Pattern, P2 <: i.Pattern, V1 <: i.Variable[P1], V2 <: i.Variable[P2]](f: P1 => P2, v: V1 => V2)(p: P1): P2 = p match {

//  def map[P <: i.Pattern, V <: i.Variable[P]](f: P => P, v: V => V)(p: P): P = p match {
//    case p:i.Variable[P]    => f(p.constructor((p.name, p.sort)))
//    case p:i.Application[P] => f(p.constructor(p.label, p.args.map(map(f,v))))
//    case p:i.DomainValue[P] => f(p.constructor((p.label, p.value)))
//    case p:i.Node0[P]       => f(p.constructor())
//    case p:i.Node1[P,P]     => f(p.constructor(p.p))
//    case p:i.Node2[P,P,P]   => f(p.constructor(p.p, p.q))
//    case p:i.Binder[V,P]    => f(p.constructor(p.v, p.p))
//  }

//  def iter[P <: i.Pattern](f: P => Unit)(p: P): Unit = p match {
//    case p:i.Leaf[P,_]      => f(p)
//    case p:i.Node0[P]       => f(p)
//    case p:i.Node1[P,P]     => f(p); iter(f)(p.p)
//    case p:i.Node2[P,P,P]   => f(p); iter(f)(p.p); iter(f)(p.q)
//    case p:i.NodeSeq[P,_,P] => f(p); p.args.foreach(iter(f))
//    case p:i.Binder[_,P]    => f(p); f(p.v); iter(f)(p.p)
//  }

  def map[P <: i.Pattern, V <: i.Variable[P,String,String]](f: P => P)(p: P): P = p match {
    case p:i.Variable[P,String,String]    => f(p.constructor(p.name, p.sort))
    case p:i.Application[P,String] => f(p.constructor(p.label, p.args.map(map(f))))
    case p:i.DomainValue[P,String,String] => f(p.constructor(p.label, p.value))
    case p:i.Node0[P]       => f(p.constructor())
    case p:i.Node1[P,P]     => f(p.constructor(p.p))
    case p:i.Node2[P,P,P]   => f(p.constructor(p.p, p.q))
//    case p:i.NodeV[P,V,P]    => f(p.constructor(p.v, p.p))
  }


  def size(p: i.Ast): Int = p match {
    case p:i.Leaf      => 1
    case p:i.Node0[_]       => 1
    case p:i.Node1[_,_]     => size(p.p)
    case p:i.Node2[_,_,_]   => size(p.p) + size(p.q)
    case p:i.NodeV[_,_,_]    => size(p.p)
    case p:i.Application[_,_] => p.args.map(size).sum
    case p:i.Node[_] => ???
    case p:i.Pattern => ???
  }

  def subst[P <: i.Pattern, V <: i.Variable[P,String,String], Vp >: i.Variable[P,String,String]](m: Map[Vp, P])(p: P): P = {
    def fresh(x: V): P = {
      x.constructor(x.name + "!new!", x.sort) // TODO: make it really fresh
    }
    p match {
      case v:i.Variable[P,String,String] => if (m.contains(v)) m(v) else p
      case p:i.NodeV[P, V, P] =>
        val x = fresh(p.v)
        p.constructor(x.asInstanceOf[V], subst(m + (p.v -> x))(p.p))
      case _ => map(subst(m))(p)
    }
  }

}
