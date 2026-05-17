
pub struct Position{
    lineStart: i32,
    columnStart: i32,
    lineFocus: i32,
    columnFocus: i32,
    lineEnd: i32,
    columnEnd: i32
}

pub const EMPTY_POSITION: Position = Position {
    lineStart: 0,
    columnStart: 0,
    lineFocus: 0,
    columnFocus: 0,
    lineEnd: 0,
    columnEnd: 0
};

pub enum ParseNode {
    Whitespace {
        //TODO should we retain the full string as well?
        pos: Position
    },
    Identifier {
        name: String,
        pos: Position
    },
    Keyword {
        name: String,
        pos: Position
    },
    IntLiteral {
        value: String, //String for now, maybe an int type later
        pos: Position
    },
    BinaryOp {
        op: String,
        lhs: Box<ParseNode>,
        rhs: Box<ParseNode>,
        pos: Position
    },
    UnaryOp {
        op: String,
        arg : Box<ParseNode>,
        pos : Position
    }
}

impl ParseNode {
    fn position(self) -> Position {
        match self {
            ParseNode::Whitespace {pos} => pos,
            ParseNode::Identifier {pos, ..} => pos,
            ParseNode::Keyword {pos, ..} => pos,
            ParseNode::IntLiteral {pos, ..} => pos,
            ParseNode::BinaryOp {pos, ..} => pos,
            ParseNode::UnaryOp {pos, ..} => pos
        }
    }
}
