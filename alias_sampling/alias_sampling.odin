package odin_alias_sampling

import "core:math/rand"
import "core:testing"
import "base:runtime"

//Supports both f32, f64
Alias_Table :: struct($T: typeid) where T == f32 || T == f64 {
	prob: []T,
	alias: []int,
	gen: runtime.Random_Generator,
	alloc: runtime.Allocator
}

deinit_alias_table_f32 :: proc(tbl: ^Alias_Table(f32)) {
	delete(tbl.prob, tbl.alloc)
	delete(tbl.alias, tbl.alloc)
	free(tbl, tbl.alloc)
}
deinit_alias_table_f64 :: proc(tbl: ^Alias_Table(f64)) {
	delete(tbl.prob, tbl.alloc)
	delete(tbl.alias, tbl.alloc)
	free(tbl, tbl.alloc)
}
deinit_alias_table :: proc {
	deinit_alias_table_f32,
	deinit_alias_table_f64
}

init_alias_table_f32 :: proc(weights: []f32,
							 gen := context.random_generator, 
							 alloc := context.allocator) -> ^Alias_Table(f32) {
	context.allocator = alloc

	n := len(weights)
	normalize_vals_f32(weights)
	small := init_stack_f32()
	large := init_stack_f32()
	defer deinit_stack(small)
	defer deinit_stack(large)

	probs := make([]f32, n)
	alias := make([]int, n)
	for i in 0..<n {
		//initial pass to add
		//stuff to worklists
		prob := weights[i]
		a := init_atom(p=prob, ind=i)
		if prob < 1 {
			//add to small
			push(small, a)
		} else {
			//>=1; add to large
			push(large, a)
		}
	}
	for !stack_empty(small) && !stack_empty(large) {
		s := pop(small)
		l := pop(large)
		probs[s.ind] = s.p
		alias[s.ind] = l.ind

		//update the large probability
		l.p = (l.p + s.p) - 1

		if l.p < 1 {
			push(small, l)
		} else {
			push(large, l)
		}
		//we finalized the small atom;
		//we can free safely
		deinit_atom(s)
	}
	for !stack_empty(large) {
		//if stuff remains stable we should end up in this branch;
		//otherwise we end up in the next one
		l := pop(large)
		probs[l.ind] = 1
		deinit_atom(l)
	}
	for !stack_empty(small) {
		//same
		s := pop(small)
		probs[s.ind] = 1
		deinit_atom(s)
	}
	out := new(Alias_Table(f32), alloc)
	out.prob = probs
	out.alias = alias
	out.gen = gen
	out.alloc = alloc
	return out
}

init_alias_table_f64 :: proc(weights: []f64,
							 gen := context.random_generator, 
							 alloc := context.allocator) -> ^Alias_Table(f64) {
	context.allocator = alloc
	n := len(weights)
	normalize_vals_f64(weights)
	small := init_stack_f64()
	large := init_stack_f64()
	defer deinit_stack(small)
	defer deinit_stack(large)

	probs := make([]f64, n)
	alias := make([]int, n)
	for i in 0..<n {
		//initial pass to add
		//stuff to worklists
		prob := weights[i]
		a := init_atom(p=prob, ind=i)
		if prob < 1 {
			//add to small
			push(small, a)
		} else {
			//>=1; add to large
			push(large, a)
		}
	}
	for !stack_empty(small) && !stack_empty(large) {
		s := pop(small)
		l := pop(large)
		probs[s.ind] = s.p
		alias[s.ind] = l.ind

		//update the large probability
		l.p = (l.p + s.p) - 1

		if l.p < 1 {
			push(small, l)
		} else {
			push(large, l)
		}
		//we finalized the small atom;
		//we can free safely
		deinit_atom(s)
	}
	for !stack_empty(large) {
		//if stuff remains stable we should end up in this branch;
		//otherwise we end up in the next one
		l := pop(large)
		probs[l.ind] = 1
		deinit_atom(l)
	}
	for !stack_empty(small) {
		//same
		s := pop(small)
		probs[s.ind] = 1
		deinit_atom(s)
	}
	out := new(Alias_Table(f64))
	out.prob = probs
	out.alias = alias
	out.gen = gen
	out.alloc = alloc
	return out
}
init_alias_table :: proc{
	init_alias_table_f32,
	init_alias_table_f64
}

sample_from_tbl_f32 :: proc(tbl: ^Alias_Table(f32)) -> int {
	//sample an index using the table

	//first, an index of the table
	//[0,n) uniform
	context.random_generator = tbl.gen
	table_ind := rand.int_range(0, len(tbl.prob))
	
	//[0,1) f32
	biased_coin_prob := rand.float32_range(0, 1)
	prob := tbl.prob[table_ind]
	if biased_coin_prob < prob {
		return table_ind
	} else {
		return tbl.alias[table_ind]
	}
}
sample_from_tbl_f64 :: proc(tbl: ^Alias_Table(f64)) -> int {
	context.random_generator = tbl.gen
	table_ind := rand.int_range(0, len(tbl.prob))
	
	biased_coin_prob := rand.float64_range(0, 1)
	prob := tbl.prob[table_ind]
	if biased_coin_prob < prob {
		return table_ind
	} else {
		return tbl.alias[table_ind]
	}
}
sample_from_tbl :: proc{
	sample_from_tbl_f32,
	sample_from_tbl_f64
}

normalize_vals_f32 :: proc(vals: []f32) {
	//normalizes vals in place to
	//"scaled probabilities"
	sum: f32 = 0
	for val in vals do sum += val
	n := len(vals)
	n_f32 := f32(n)
	for i in 0..<n {
		vals[i] = vals[i]/sum*n_f32
	}
}
normalize_vals_f64 :: proc(vals: []f64) {
	//normalizes vals in place to
	//"scaled probabilities"
	sum: f64 = 0
	for val in vals do sum += val
	n := len(vals)
	n_f64 := f64(n)
	for i in 0..<n {
		vals[i] = vals[i]/sum*n_f64
	}
}
normalize_vals :: proc {
	normalize_vals_f32,
	normalize_vals_f64
}
