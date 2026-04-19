/// Alignment along the main (flow) axis. For a Column that's vertical,
/// for a Row horizontal. Only takes effect when the flex widget has
/// slack on the main axis — i.e. the parent gives it more space than
/// the children consume.
enum MainAxisAlignment { start, center, end, spaceBetween, spaceAround, spaceEvenly }

/// Alignment along the cross (perpendicular) axis. Each child is
/// positioned independently within the flex's cross-axis extent,
/// which is the widest/tallest child.
enum CrossAxisAlignment { start, center, end }
