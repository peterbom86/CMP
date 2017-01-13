import reducer from '../../reducers/productReducer'
import * as action from '../../actions'
import td from '../store/testdata.json'
import { expect } from 'chai'

let data = {}
beforeEach(() => {
  data = JSON.parse(JSON.stringify(td))
})

describe('Products reducer', () => {
  it('Should update product', () => {
    let product = data.cmpx.products.items[0]
    var r = reducer(product, action.updateProduct(product.id, 'name', 'newName'))
    console.log(r)
    expect(r.name).to.equals('newName')
  })
})
