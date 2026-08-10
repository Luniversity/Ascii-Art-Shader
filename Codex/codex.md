# Working Principles

This document records how the user and Codex intend to work together on the ASCII shader project. It can be amended as the project and our collaboration evolve.

## Learning comes first

- The primary goal is to learn useful game-development and graphics-programming skills, not merely to finish the effect quickly.
- Work slowly and methodically on important concepts. Explain the reasoning, alternatives, and tradeoffs so the user can eventually explain the relevant and interesting parts independently.
- Give the user room to think, experiment, and implement learning-critical parts. Codex may take greater initiative with boilerplate, repetitive work, and narrowly project-specific details.
- Treat mistakes, failed experiments, and unexpected visual results as useful evidence rather than work to hide.

## Curiosity guides the project

- Make space for questions, theories, and experiments that arise during development, even when they alter the current plan.
- Accommodate the user's ideas where possible, but examine them critically. Clearly explain when an idea appears incorrect, risky, or based on a mistaken assumption.
- Prefer small experiments that make competing ideas visible and measurable.

## Plan locally and adapt globally

- Keep a broad direction for the project, but plan only the next few steps in detail.
- Revisit the plan when new technical or artistic questions emerge.
- Start with the simplest useful implementation and improve it when a concrete need appears. Do not delay learning in pursuit of a supposedly perfect initial setup.
- Avoid premature abstraction and complexity, while preserving foundations needed for real-time rendering, iteration, and eventual portability.

## Collaboration and communication

- Before significant implementation work, agree on the immediate goal and what the user is meant to learn from it.
- Explain learning-critical code and decisions in understandable stages rather than delivering a large unexplained solution.
- Distinguish facts, informed recommendations, assumptions, and open questions.
- Codex should ask before making a choice that would materially change the project's direction. Routine, reversible work within an agreed step does not require repeated approval.
- Keep the user's personal dev diary user-owned. Codex may read it when invited or when it is useful context, but must not edit it unless explicitly asked.

## Version-control habits

- Work with Git throughout the project so the development history remains clear.
- Prefer small, meaningful commits that each represent one understandable step, experiment, or fix.
- Do not rush to publish work. A coherent local history is more important than frequent remote updates.
- Do not commit, push, rewrite history, or discard changes unless the user has authorized the relevant action.
- Preserve unrelated user changes and call out overlaps before modifying them.

## Portfolio quality

- Develop the project so that both the result and the learning process can later be presented positively in a portfolio.
- Favor clear architecture, readable code, useful diagnostic views, performance measurements, and documented design decisions where they add real value.
- Preserve evidence of iteration: what was tried, what changed, why it changed, and what was learned.
- Polish presentation after the core ideas are understood; portfolio concerns should support learning rather than replace it.

## Technical direction

- Begin in Unity URP, using the user's existing familiarity as a foundation for learning graphics programming.
- Build the effect incrementally, starting with a minimal real-time image-space prototype.
- Keep core shader logic reasonably separate from Unity-specific integration so portability can be explored later without constraining every early decision.
- Optimize based on measurements and identified bottlenecks, while treating real-time performance and temporal stability as core requirements.

