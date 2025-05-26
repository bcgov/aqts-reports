# ---
# jupyter:
#   jupytext:
#     formats: ipynb,py:percent
#     text_representation:
#       extension: .py
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.16.1
#   kernelspec:
#     display_name: Python 3 (ipykernel)
#     language: python
#     name: python3
# ---

# %%
# Run this app with `python app.py` and
# visit http://127.0.0.1:8050/ in your web browser.

from dash import Dash, html, dash_table, dcc, callback, Output, Input
import plotly.express as px
import pandas as pd
import dash_bootstrap_components as dbc


app = Dash()

colors = {
    'background': '#FFFFFF',
    'text': '#154360'
}

# assume you have a "long-form" data frame
# see https://plotly.com/python/px-arguments/ for more options
df = pd.DataFrame({
    "Fruit": ["Apples", "Oranges", "Bananas", "Apples", "Oranges", "Bananas"],
    "Amount": [4, 1, 2, 2, 4, 5],
    "City": ["SF", "SF", "SF", "Montreal", "Montreal", "Montreal"]
})

fig = px.bar(df, x="Fruit", y="Amount", color="City", barmode="group")

fig.update_layout(
    plot_bgcolor=colors['background'],
    paper_bgcolor=colors['background'],
    font_color=colors['text']
)

app.layout = dbc.Container([
    # Title
    dbc.Row([
        html.Div(style={'backgroundColor': colors['background']}, children=[
            html.H1(
                children='Automated Snow Weather Station Dashboard',
                style={
                    'textAlign': 'left',
                    'color': colors['text'],
                    'font-family':'Arial, Helvetica, sans-serif',
                    'font-size': '40px',
                    'font-weight': 'bold'
                }
            )
        ])
    ]),
    # Tabs
    dbc.Row([
        html.Div([
        dcc.Tabs(id='tabs', value='tab-1', children=[
            dcc.Tab(label='Station Health', value='tab-1'),
            dcc.Tab(label='7 Day Inter-Station', value='tab-2'),
            dcc.Tab(label='Historical', value='tab-3') 
            ]),
        ])
    ]),

    # Content
    dbc.Row([
        # Dropdown
        dbc.Col([
            html.Div([
                dcc.Dropdown(['NYC', 'MTL', 'SF'], 'NYC', id='demo-dropdown'),
                html.Div(id='dd-output-container')
            ])
        ], width=1),
        # Plot
        dbc.Col([
             dcc.Graph(
                id='example-graph-2',
                figure=fig
            )
        ], width=1)
    ])
])

if __name__ == '__main__':
    app.run(debug=True)

