package odin_alias_sampling

import "core:testing"

//the algorithm requires a worklist;
//a stack was thus implemented here.

@(private)
Stack :: struct($T: typeid) where T == f32 || T == f64{
	//a stack of Atoms.
	top: ^Atom_Linked(T), //will be nil if empty
	len: int
}

@(private)
Atom :: struct($T: typeid) where T == f32 || T == f64{
	p: T,
	ind: int,
}

@(private)
Atom_Linked :: struct($T: typeid) where T == f32 || T == f64 {
	a: ^Atom(T),
	next: ^Atom_Linked(T)
}

@(private)
init_atom_f32 :: proc(p: f32, ind: int) -> ^Atom(f32) {
	out := new(Atom(f32))
	out.p = p
	out.ind = ind
	return out
}

@(private)
init_atom_f64 :: proc(p: f64, ind: int) -> ^Atom(f64) {
	out := new(Atom(f64))
	out.p = p
	out.ind = ind
	return out
}


@(private)
init_atom :: proc {
	init_atom_f32,
	init_atom_f64
}


@(private)
init_stack_f32 :: proc() -> ^Stack(f32) {
	return new(Stack(f32))
}
@(private)
init_stack_f64 :: proc() -> ^Stack(f64) {
	return new(Stack(f64))
}

@(private)
deinit_stack :: proc(s: ^Stack) {
	free(s)
}

@(private)
deinit_atom :: proc(a: ^Atom) {
	free(a)
}

@(private)
push_f32 :: proc(s: ^Stack(f32), a: ^Atom(f32)) {
	linked := new(Atom_Linked(f32))
	linked.a = a
	linked.next = s.top
	s.top = linked
	s.len += 1
}
@(private)
push_f64 :: proc(s: ^Stack(f64), a: ^Atom(f64)) {
	linked := new(Atom_Linked(f64))
	linked.a = a
	linked.next = s.top
	s.top = linked
	s.len += 1
}
@(private)
push :: proc{
	push_f32,
	push_f64
}

@(private)
pop_f32 :: proc(s: ^Stack(f32)) -> ^Atom(f32) {
	assert(!stack_empty(s), "Attempt to pop from an empty stack")
	out := s.top.a
	free(s.top)
	s.top = s.top.next
	s.len -= 1
	return out
}
@(private)
pop_f64 :: proc(s: ^Stack(f64)) -> ^Atom(f64) {
	assert(!stack_empty(s), "Attempt to pop from an empty stack")
	out := s.top.a
	free(s.top)
	s.top = s.top.next
	s.len -= 1
	return out
}
@(private)
pop :: proc {
	pop_f32,
	pop_f64
}

@(private)
stack_empty_f32 :: proc(s: ^Stack(f32)) -> bool {
	if s.len == 0 do return true
	return false
}

@(private)
stack_empty_f64 :: proc(s: ^Stack(f64)) -> bool {
	if s.len == 0 do return true
	return false
}

@(private)
stack_empty :: proc {
	stack_empty_f32,
	stack_empty_f64
}

@(test)
test_stack_f32 :: proc(t: ^testing.T) {
	s := init_stack_f32()
	defer deinit_stack(s)
	a := init_atom(f32(0.01), 2)
	b := init_atom(f32(0.2), 1)
	defer free(a)
	defer free(b)
	push(s, a)
	push(s, b)
	pop1 := pop(s)
	pop2 := pop(s)
	testing.expect_value(t, pop1.p, f32(0.2))
	testing.expect_value(t, pop1.ind, 1)
	testing.expect_value(t, pop2.p, f32(0.01))
	testing.expect_value(t, pop2.ind, 2)
}

@(test)
test_stack_f64 :: proc(t: ^testing.T) {
	s := init_stack_f64()
	defer deinit_stack(s)
	a := init_atom(f64(0.01), 2)
	b := init_atom(f64(0.2), 1)
	defer free(a)
	defer free(b)
	push(s, a)
	push(s, b)
	pop1 := pop(s)
	pop2 := pop(s)
	testing.expect_value(t, pop1.p, f64(0.2))
	testing.expect_value(t, pop1.ind, 1)
	testing.expect_value(t, pop2.p, f64(0.01))
	testing.expect_value(t, pop2.ind, 2)
}
