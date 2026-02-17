# Work Item Description Templates

## User Story Description

```html
<h2>Overview</h2>
<p>{Phase description from plan}</p>

<h2>Plan Reference</h2>
<p>Implementation Plan: {plan path}</p>
<p>Phase: {N} of {total}</p>

<h2>Changes Required</h2>
<ul>
{list of files and changes}
</ul>

<h2>Success Criteria</h2>
<h3>Automated Verification</h3>
<ul>
<li>{automated check 1}</li>
<li>{automated check 2}</li>
</ul>

<h3>Manual Verification</h3>
<ul>
<li>{manual check 1}</li>
</ul>

<h2>SWE Suitability</h2>
<p>{Yes/No with reasoning}</p>
```

## Task Description

```html
<h2>Change</h2>
<p>{Detailed change description}</p>

<h2>File</h2>
<p><code>{file path}</code></p>

<h2>Pattern Reference</h2>
<p>See <code>{similar file:line}</code> for implementation pattern.</p>

<h2>Code Changes</h2>
<pre><code>
{code snippet if provided in plan}
</code></pre>
```
