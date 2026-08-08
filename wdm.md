Personal Decision Intelligence System (PDIS)
A full-stack, AI-powered web application that helps you make structured, intelligent decisions using a Weighted Decision Matrix. PDIS combines deterministic mathematical scoring with generative AI (Groq) to provide criteria suggestions, option discovery, and actionable insights.

PDIS Screenshot Placeholder

🚀 Features
AI-Assisted Brainstorming: Uses the Groq API to automatically suggest relevant evaluation criteria, realistic options, and suitable weights based on your decision context.
Deterministic Scoring Engine: Core mathematical calculations are handled purely in Python, ensuring accurate, transparent, and reproducible weighted rankings.
Smart RAG Memory System: Automatically saves past decisions as JSON and uses them to intelligently inform the AI on future related decisions (no heavy database required).
Decision Learning Timeline: Track, review, and learn from past decisions. Mark outcomes as correct/incorrect, add reflection notes, and identify patterns in your decision-making over time.
Speech-to-Text Input: Voice-powered decision context entry using Web Speech API for natural, hands-free input.
Interactive Sensitivity Analysis: Real-time weight adjustment with instant ranking recalculation, stability indicators, and critical criteria detection. Understand how your decision changes with different priorities.
Decision Confidence Score: Data-driven reliability assessment that evaluates decision quality based on criteria depth, weight balance, score separation, and stability. Get High/Medium/Low confidence ratings with actionable warnings.
Bias Detection System: Analyzes historical decisions to identify consistent behavioral patterns like over-prioritizing certain criteria, neglecting long-term factors, or habitual decision structures. Provides personalized recommendations to improve decision-making.
Scenario Simulation: Explore how your decision changes under different future conditions. Create multiple scenarios with varying priorities, compare outcomes side-by-side, and identify robust choices that work across situations.
Insights Generator: Post-decision analysis that highlights pros, cons, and risks based on the final calculated scores.
Stunning UI: Modern, responsive, glassmorphic design built with Tailwind CSS and Vanilla JS.




How it Works (The Flow)
Context Phase: You input the decision you need to make (e.g., "Which cloud provider to use?").
AI Phase (Optional): Groq analyzes your context, compares it to past decisions in data/decisions/, and suggests criteria (Cost, Speed, Support) and options (AWS, GCP, Azure).
Scoring Phase: You rate each option 1-5 across your criteria.
Engine Phase: The Python backend deterministically calculates the weighted sums and ranks the options.
Insight Phase: Groq returns actionable pros/cons based on the math.
Save Phase: The entire matrix is saved to a .json file to inform future suggestions.
Learning Phase: After implementing your decision, return to the Timeline to review the outcome, mark it as correct/incorrect, and add reflection notes to improve future decisions.
