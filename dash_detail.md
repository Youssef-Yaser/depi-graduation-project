📊 Enterprise Aviation Analytics & KPI Dashboards
Our data model terminates into a two-page interactive Power BI reporting dashboard, connected directly via secure DirectQuery / Import interfaces to the validated dimensional models inside Snowflake.

📈 Page 1: Executive Operations Overview
An executive-level tracking environment providing a macro perspective on operational velocity across 14 Million flight transactions.

Core Operational KPIs:
Volume: 14,000,000 Total Logged Flights.
Reliability: 78.8% On-Time Arrival Efficiency.
Volatility: 1.41% System-wide Flight Cancellation Rate.
Departure Friction: Average departure offset stands at 13.1 minutes.
Visual Breakdowns:
Carrier Market Share: Bar chart grouping volume by airline, identifying Southwest Airlines and Delta Air Lines as volume leaders.
Cancellation Attribution: Donut visual isolating root failure modes; Weather accounts for 58.74% of cancellations, followed by Carrier constraints at 26.11%.
Temporal Scaling: Line-chart analyzing transaction volume seasonality over 12 operational months.
📉 Page 2: Advanced Delay Analytics & Root-Cause Diagnostics
A deep-dive analytical view designed for operational managers to isolate and minimize flight delay vectors.

Delay Drivers (The "Why"): Stacked horizontal metrics breakdown delay time vectors directly into operational root causes: Late Aircraft Arrival, Carrier Operations, National Air System (NAS), and Severe Weather.
Geospatial / Regional Performance: Matrix views identifying high-traffic hubs by state (e.g., Texas logging 1.5M flights with an 11-minute average arrival delay) paired with a ranking of the highest overall delays by state.
Hub Typing: Tree-map visual evaluating flight delays relative to regional infrastructure scale, identifying Small Airports as higher delay vectors (Avg 15.95 mins) vs Large Hubs (Avg 7.68 mins) due to equipment constraints.
