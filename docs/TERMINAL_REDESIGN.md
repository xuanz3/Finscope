# Terminal redesign / RC3

Project owner: Xuanze Chen.

## Visual system
- Near-black navy shell, charcoal panels, muted dividers, restrained brand accents.
- Compact navigation and horizontal workspace tabs.
- Overview leads with the screener; Markets leads with the price chart.
- Flat account strip, striped rows, source labels, comparative returns and ranked returns.
- Responsive three-column, two-column and single-column layout.

## Motion
- Control press: 95 ms; hover and selection: 140 ms; navigation: 280 ms.
- Data and chart appearance: 270 ms; numeric values and ranking bars: 380 ms.
- Reduced-motion preference disables timed transitions. No animation changes execution or stored prices.

## Validation
- Existing financial core preserved. Previous bootstrap indentation defect corrected.
- Local shell and embedded Python syntax checked. Flutter compilation, widget tests, rendering and frame rates still require a Flutter host.
