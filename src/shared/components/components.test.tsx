import { fireEvent, render, screen } from '@testing-library/react'
import { useState } from 'react'
import { describe, expect, it, vi } from 'vitest'
import { Button, Calendar, CodeInput, monthWeeks, PasswordField, TextField, toIsoDay } from '.'

describe('Button', () => {
  it('mientras carga no se puede presionar', () => {
    const onClick = vi.fn()
    render(
      <Button loading onClick={onClick}>
        Creando cuenta…
      </Button>,
    )
    fireEvent.click(screen.getByRole('button'))
    expect(onClick).not.toHaveBeenCalled()
    expect(screen.getByRole('button')).toHaveAttribute('aria-busy', 'true')
  })
})

describe('Campos', () => {
  it('relaciona el mensaje de error con el campo', () => {
    render(<TextField label="Correo" error="Escribe un correo válido." />)
    const input = screen.getByLabelText('Correo')
    expect(input).toHaveAttribute('aria-invalid', 'true')
    expect(input).toHaveAccessibleDescription(/Escribe un correo válido/)
  })

  it('muestra y oculta la contraseña', () => {
    render(<PasswordField label="Contraseña" />)
    const input = screen.getByLabelText('Contraseña')
    expect(input).toHaveAttribute('type', 'password')
    fireEvent.click(screen.getByRole('button', { name: 'Mostrar' }))
    expect(input).toHaveAttribute('type', 'text')
  })
})

function Code() {
  const [value, setValue] = useState('')
  return (
    <>
      <CodeInput value={value} onChange={setValue} />
      <output>{value}</output>
    </>
  )
}

describe('CodeInput', () => {
  it('acepta un código pegado y descarta lo que no es número', () => {
    render(<Code />)
    fireEvent.paste(screen.getByLabelText('Dígito 1 de 6'), {
      clipboardData: { getData: () => '48 2-913 77' },
    })
    expect(screen.getByRole('status')).toHaveTextContent('482913')
  })

  it('borra con la tecla de retroceso', () => {
    render(<Code />)
    fireEvent.change(screen.getByLabelText('Dígito 1 de 6'), { target: { value: '4' } })
    fireEvent.keyDown(screen.getByLabelText('Dígito 2 de 6'), { key: 'Backspace' })
    expect(screen.getByRole('status')).toHaveTextContent('')
  })
})

describe('Calendario', () => {
  it('las semanas empiezan en lunes', () => {
    // El 1 de marzo de 2027 es lunes; el 1 de mayo de 2027, sábado.
    expect(monthWeeks(2027, 2)[0][0]?.getDate()).toBe(1)
    expect(monthWeeks(2027, 4)[0].slice(0, 5)).toEqual([null, null, null, null, null])
    expect(toIsoDay(new Date(2027, 2, 5))).toBe('2027-03-05')
  })

  it('solo deja elegir días con algún turno libre', () => {
    const onSelect = vi.fn()
    render(
      <Calendar
        year={2027}
        month={2}
        days={{ '2027-03-05': 'partial', '2027-03-06': 'busy' }}
        onSelect={onSelect}
      />,
    )
    fireEvent.click(screen.getByRole('button', { name: /^5 de marzo.*Un turno libre/ }))
    expect(onSelect).toHaveBeenCalledWith('2027-03-05')
    expect(screen.getByRole('button', { name: /^6 de marzo.*Ocupado/ })).toBeDisabled()
    // Sin información no se puede reservar.
    expect(screen.getByRole('button', { name: '7 de marzo de 2027' })).toBeDisabled()
  })
})
