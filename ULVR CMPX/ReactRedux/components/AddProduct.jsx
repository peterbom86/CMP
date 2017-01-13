import React, { PropTypes } from 'react'
import { updateProduct, addProduct } from '../actions'

class AddProduct extends React.Component {
  onNewProductEdit(text) {
    // var newProduct = { Name: text, id: this.state.newProduct.id }
    // this.setState({ newProduct: newProduct })
  }
  onAddUpdateProduct(product) {
    if (product.id) {
      this.context.store.dispatch(addProduct(product))
    }

    console.log(product)
  }
  onUpdateProduct(id, prop, value) {
    this.context.store.dispatch(updateProduct(id, prop, value))
  }
  render() {
    console.log(this.props.product)
    return (
      <div>
        {/* <a href="javascript:void(0)" onClick={(e) => { this.setState({ showCreate: !this.state.showCreate }) } }>{this.state.showCreate ? "Close" : "Create new"}</a> */}
        <div>
          <input value={this.props.product.text || ''} type="text" onChange={(e) => { this.onUpdateProduct(this.props.product.id, 'text', e.target.value) } } />
          <button onClick={(e) => { this.onAddUpdateProduct(this.state) } }>Ok</button>
        </div>
      </div>)
  }
}
AddProduct.contextTypes = {
  store: PropTypes.object.isRequired
}
AddProduct.propTypes = {
  product: PropTypes.object.isRequired
}
export default AddProduct
