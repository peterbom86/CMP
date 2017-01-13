import reducer from '../../reducers/cmpx'
import * as action from '../../actions'
import td from '../store/testdata.json'
import { expect } from 'chai'

let data = {}
beforeEach(() => {
  data = JSON.parse(JSON.stringify(td))
})

describe('CMPX reducer', () => {
  it('should add an item to the list', () => {
    var r = reducer(data.cmpx, action.addProduct({ text: 'Testdataww', id: 'jnjlb sfs' }))

    expect(r.products.items.length).to.equals(2)
  })
})
