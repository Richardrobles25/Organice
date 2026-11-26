import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import App from './App.tsx'

describe('App', () => {
  it('muestra el nombre de ORGANICE', () => {
    render(<App />)
    expect(screen.getByRole('heading', { name: 'ORGANICE' })).toBeInTheDocument()
  })
})
