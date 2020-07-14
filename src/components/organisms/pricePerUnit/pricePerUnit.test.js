import React from 'react'
import { shallow } from 'enzyme'

import PricePerUnit from './pricePerUnit'
import { CALCULATOR_STEPS } from '../../../constants/constants'

describe('PricePerUnit', () => {
  const setUnitPriceMock = jest.fn()
  const goToStepMock = jest.fn()
  const restartMock = jest.fn()

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders money input field and submit button', () => {
    const wrapper = shallow(<PricePerUnit />)
    expect(wrapper.find('MoneyInput')).toHaveLength(1)
    expect(wrapper.find('FormButton')).toHaveLength(1)
  })

  it('calls setUnitPrice on change', () => {
    const wrapper = shallow(
      <PricePerUnit setUnitPrice={setUnitPriceMock} goToStep={goToStepMock} />
    )
    wrapper.find('MoneyInput').simulate('change', null, {value: 100})
    expect(setUnitPriceMock).toHaveBeenCalledWith(100)
  })  

  it('goes to the next step on submit', () => {
    const wrapper = shallow(
      <PricePerUnit goToStep={goToStepMock} />
    )
    wrapper.find('Form').simulate('submit')
    expect(goToStepMock).toHaveBeenCalledWith(CALCULATOR_STEPS.PRICE_PER_UNIT + 1)
  })

  it('goes to the previous step on back click', () => {
    const wrapper = shallow(
      <PricePerUnit goToStep={goToStepMock} />
    )
    wrapper.find('a').first().simulate('click')
    expect(goToStepMock).toHaveBeenCalledWith(CALCULATOR_STEPS.PRICE_PER_UNIT - 1)
  })

  it('calls restart prop on restart analysis click', () => {
    const wrapper = shallow(
      <PricePerUnit restart={restartMock} />
    )
    wrapper.find('a').last().simulate('click')
    expect(restartMock).toHaveBeenCalledTimes(1)
  })
})