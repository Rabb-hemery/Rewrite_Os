# Rewrite_Os
Building an OS from scratch ( bootloader, kernel, memory management and a basic shell, inspired by Linux, TempleOS and GrapheneOS.)

## Day 0 — Project Overview

Rewrite_OS is a personal project aimed at building, from scratch, the
fundamental building blocks of an operating system: a bootloader, a
minimal kernel, memory management, and a basic shell.

The goal is not to produce a daily-driver OS. This is a learning
project: understanding, by building it myself, what actually happens
between the moment a computer powers on and the moment an operating
system takes over.

## Inspirations

Three systems have shaped the direction of this project, each for a
different reason:

- **Linux** — for its ecosystem and robustness; a reference for what
  a well-built kernel can do.
- **TempleOS** — for its radical simplicity; proof that a single
  developer can build a complete, coherent system from nothing.
- **GrapheneOS** — for its approach to security; an inspiration for
  thinking about a system's design from the start, rather than
  patching it afterward.

The idea isn't to copy these systems, but to understand the choices
they made and draw inspiration from them for Rewrite_OS.

## Starting Constraints

To set an honest frame for what's ahead:

- Solid background in C, but **no experience with x86 assembly** —
  a real obstacle to tackle from the very first steps (the
  bootloader is largely written in assembly).
- All development and testing happen **inside a virtual machine**
  (VirtualBox/QEMU), to never risk damaging my actual machine.
- The project is planned over **30 days**, at **5+ hours per day**.

## Roadmap (Major Phases)

Development is split into four major phases, in this order:

1. **Bootloader** — understanding how a PC boots, writing the very
   first code executed by the processor, and handing off control to
   the kernel.
2. **Minimal kernel** — switching to protected mode, printing text to
   the screen, basic interrupt handling.
3. **Memory management** — basic segmentation and/or paging, so the
   system can allocate and protect memory.
4. **Basic shell** — minimal keyboard interaction, to type commands
   and see the system respond.

Each phase will be documented as it happens, including the
difficulties encountered and the decisions made along the way.

## Progress Log

Each day of development will be logged (devlog, commits, notes) to
keep an honest record of real progress — successes as well as
roadblocks.
