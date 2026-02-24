# Odin-Alias-Sampling

An odin implementation of Vose's Alias Method for sampling from arbitrary
non-uniform discrete distributions. Particularly useful when many samples are
needed so that constant time sampling is necessary. Initialization time and
memory usage are both O(n). 

For details, [this](https://www.keithschwarz.com/darts-dice-coins/) is a nice read.

## Installation

Copy the ```alias_sampling``` directory into your project and import it as needed.

## Usage

Alias tables are initialized with the ```init_alias_table``` procedure using
a slice of floating point dimensionless weights. Preprocessing is done
on the weights slice in-place; if they are required for a purpose other
than initializing the alias table, make sure to pass a copied slice.

```init_alias_table``` is implemented to be parametrically polymorphic,
so you may pass it either a slice of f32 or f64. The exact API is
```odin
init_alias_table(weights: []T, gen: runtime.Random_Generator, alloc: runtime.Allocator) -> ^Alias_Table(T) {...} 
```
where T is f32 or f64. If gen or alloc are not provided, the caller's context
is used.

Once an alias table is initialized, indices of the weights slice can be sampled
proportional to their corresponding weights by passing the table into
```sample_from_tbl```. 

Initializing an alias table allocates memory; use ```deinit_alias_table``` to
free.

## Example

```odin
package example

import asam "alias_sampling"
import "core:fmt"

main :: proc() {
	vals := make([]f64, 4)
	//skewed distribution
	vals[0] = 2 //7.14%
	vals[1] = 4 //14.28%
	vals[2] = 8 //28.57%
	vals[3] = 14 //50%
	tbl := asam.init_alias_table(vals)
	delete(vals)
	defer asam.deinit_alias_table(tbl)

    //counters for index samples
	zeros := 0
	ones := 0
	twos := 0
	threes := 0

	n := 1000000 //number of samples
	for i in 0..<n {
		val := asam.sample_from_tbl(tbl)
		if val == 0 do zeros += 1
		if val == 1 do ones += 1
		if val == 2 do twos += 1
		if val == 3 do threes += 1
	}
	//print results
	fmt.println("Proportion of 0: ", f64(zeros)/f64(n))
	fmt.println("Proportion of 1: ", f64(ones)/f64(n))
	fmt.println("Proportion of 2: ", f64(twos)/f64(n))
	fmt.println("Proportion of 3: ", f64(threes)/f64(n))	
}
```
Example output:
```shell
Proportion of 0:  0.071344
Proportion of 1:  0.14286299999999999
Proportion of 2:  0.28567799999999999
Proportion of 3:  0.50011499999999998
```
