# Demo how to launch array job on a slurm HPC cluster

Consider the task of launching a simulation that repeats `B` times a stochastic process and that save a given vector of results `theta`. One can efficiently parallelize such a simulation using array jobs in a slurm cluster. (The Slurm Workload Manager)[https://slurm.schedmd.com/documentation.html] , formerly known as Simple Linux Utility for Resource Management, or simply Slurm, is a free and open-source job scheduler for Linux and Unix-like kernels, used by many of the world's supercomputers and computer clusters.
