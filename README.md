# GeneticAlgorithms

An example of genetic algorithm.

## The problem

Given the digits `0` through `9` and the operators `+`, `-`, `*` and `/`,  find a sequence that will represent a given target number. The operators will be applied sequentially from left to right as you read.
 
So, given the target number `23`, the sequence `6 + 5 * 4 / 2 + 1` would be one possible solution.
 
If `75.5` is the chosen number then `5 / 2 + 9 * 7 - 5` would be a possible solution.

More informations about the problem [here](http://www.ai-junkie.com/ga/intro/gat3.html). 

## The solution

### Try it

To run the solution, you can do the following:
```
> chmod +x script.swift
> ./script.swift
```
### Tweak it

You can change the different parameters of the `compute` function to have a better understanding of what is going on:
- `optimal`: Value to find
- `dnaSize`: Length of the solution
- `populationSize`: Number of individuals in a population
- `generations`: Number of generations created before calculating fitness on a population
- `mutationChance`: Chance that the dna will mutate with each generation, `1 / mutationChance`

### References

The script is inspired from [https://gist.github.com/blainerothrock/efda6e12fe10792c99c990f8ff3daeba](https://gist.github.com/blainerothrock/efda6e12fe10792c99c990f8ff3daeba)
