/**
 * Chart palette, kept out of the component file so fast refresh stays intact.
 *
 * The two-series pair was validated with the data-viz palette checker against a
 * white surface across all pairs: lightness band, chroma floor, CVD separation
 * (ΔE 25.9 deutan), normal-vision separation (ΔE 28.0) and contrast all pass.
 *
 * Magnitude charts use `sequential` as a single hue stepped by opacity, because
 * comparing sizes is a magnitude job rather than an identity one.
 *
 * Bin colours live in index.css as product data. Red and green fail CVD
 * separation against each other, so bin marks are always direct-labelled and
 * colour never carries the meaning on its own.
 */
export const chartColors = {
  series1: '#00863b',
  series2: '#1c64d7',
  sequential: '#00863b',
  negative: '#db2c2b',
  grid: 'oklch(0.92 0 0)',
  axis: 'oklch(0.55 0 0)',
}

export const binVars = {
  BLUE: 'var(--bin-blue)',
  GREEN: 'var(--bin-green)',
  RED: 'var(--bin-red)',
  GREY: 'var(--bin-grey)',
}
