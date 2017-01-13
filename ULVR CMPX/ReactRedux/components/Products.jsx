import React from 'react'
// import moment from 'moment'
// import AddProduct from '../components/AddProduct'
import { deleteProduct, addProduct, cancelSaveProduct, fetchProducts, saveProduct, updateProductsProductGroup, updateProduct, fetchProductGroups } from '../actions'
import { connect } from 'react-redux'
import getMuiTheme from 'material-ui/styles/getMuiTheme'
import { RaisedButton, TextField } from 'material-ui'
import { Table, TableBody, TableHeader, TableHeaderColumn, TableRow, TableRowColumn } from 'material-ui/Table'
import EditField from './EditField'

class Products extends React.Component {
  constructor(props) {
    super(props)
    this.state = { hoverId: null, editId: null }
    this._searchText = ''
  }

  getChildContext() {
    return { muiTheme: getMuiTheme() }
  }
  onFilterProducts(searchText, max) {
    if (searchText === '') {
      return
    }
    this.props.onFilterProducts(searchText, max)
    this._searchText = searchText
  }
  onAddProduct() {
    this.props.onAddProduct({ id: null })
  }
  render() {
    const searchFoundText = this.props.totalItemCount === 0 ? 'Seach products' : 'Seach products (' + this.props.totalItemCount + ' found)'
    return (
      <div>
        <div>
          <TextField floatingLabelText={searchFoundText} onChange={(e) => { this.onFilterProducts(e.target.value) } } />
          <RaisedButton label="Get All" primary={true} onClick={(e) => { this.onFilterProducts(this._searchText, this.props.totalItemCount) } } />
          <RaisedButton label="Add Product" primary={true} onClick={(e) => { this.onAddProduct() } } />
        </div>
        <div style={{ width: '1024px' }}>
          <Table selectable={false} fixedHeader={false} height='500px'>
            <TableHeader adjustForCheckbox={false} displaySelectAll={false}>
              <TableRow>
                <TableHeaderColumn>Name</TableHeaderColumn>
                <TableHeaderColumn>Group</TableHeaderColumn>
                <TableHeaderColumn>Category</TableHeaderColumn>
                <TableHeaderColumn>Code</TableHeaderColumn>
                <TableHeaderColumn></TableHeaderColumn>
              </TableRow>
            </TableHeader>
            <TableBody adjustForCheckbox={false} displayRowCheckbox={false}>
              {this.props.products.map((p, i) => {
                let isEditVisible = p.id === this.state.hoverId
                let isOkVisible = this.state.editId != null && this.state.editId === this.state.hoverId && p.id === this.state.hoverId || p.id == null
                if (isOkVisible) {
                  isEditVisible = false
                }
                let isEditable = p.id === this.state.editId || p.id == null
                return (
                  <TableRow hoverable={true} key={i} onMouseLeave={(a) => { this.setState({ hoverId: null }) } } onMouseEnter={(a) => { this.setState({ hoverId: p.id }) } }>
                    <TableRowColumn><EditField onChange={(e) => { this.props.onUpdateProduct(p.id, 'name', e.target.value) } } type="text" floatingText="Name" isEditable={isEditable} value={p.name} /></TableRowColumn>
                    <TableRowColumn>
                      <EditField
                        onSearch={(searchText) => { this.props.onSearchProductGroups(searchText, 20) } }
                        onChange={(selectedObject, index) => { this.props.onChangeProductGroups(p.id, selectedObject) } }
                        value={p.productGroupName}
                        isEditable={isEditable}
                        filter={() => (searchText, key) => true}
                        dataSource={this.props.productgroups}
                        type="combo"
                        floatingText="Group"
                        isEditable={isEditable} />
                    </TableRowColumn>
                    <TableRowColumn><span>{p.productGroupProductCategoryName}</span></TableRowColumn>
                    <TableRowColumn><EditField floatingText="Code" isEditable={isEditable} value={p.productCode} /></TableRowColumn>
                    <TableRowColumn>
                      <a style={{ display: isEditVisible ? '' : 'none' }} href="javascript:void(0)" onClick={(e) => { this.setState({ editId: p.id }) } } >Edit</a>
                      <a style={{ display: isOkVisible ? '' : 'none' }} href="javascript:void(0)" onClick={(e) => { this.props.onSaveClicked(p); this.setState({ editId: null }) } } >Save</a><span>&nbsp;</span>
                      <a style={{ display: isOkVisible ? '' : 'none' }} href="javascript:void(0)" onClick={(e) => { this.props.onCancelClicked(p); this.setState({ editId: null }) } } >Cancel</a>
                    </TableRowColumn>
                  </TableRow>
                )
              })
              }
            </TableBody>
          </Table>
        </div >
      </div >
    )
  }
}

const mapStateToProps = (state) => {
  return {
    products: state.cmpx.products.items,
    productgroups: state.cmpx.productGroups.items,
    totalItemCount: state.cmpx.products.meta.totalItemCount
  }
}
const mapDispatchToProps = (dispatch) => {
  return {
    onFilterProducts: (searchText, max) => {
      dispatch(fetchProducts(searchText, max)).then(() =>
        console.log('fetchProducts')
      )
    },
    onUpdateProduct: (id, prop, value) => {
      dispatch(updateProduct(id, prop, value))
    },
    onSaveClicked: (product) => {
      dispatch(saveProduct(product))
    },
    onCancelClicked: (product) => {
      if (product.id == null) {
        dispatch(deleteProduct(product.id))
      } else {
        dispatch(cancelSaveProduct(product.id))
      }
    },
    onSearchProductGroups: (searchText, max) => {
      dispatch(fetchProductGroups(searchText, max))
    },
    onChangeProductGroups: (id, selectedObject) => {
      dispatch(updateProductsProductGroup(id, selectedObject))
    },
    onAddProduct: (product) => {
      dispatch(addProduct(product))
    }

  }
}
Products.childContextTypes = {
  muiTheme: React.PropTypes.object.isRequired
}

export default connect(mapStateToProps, mapDispatchToProps)(Products)
