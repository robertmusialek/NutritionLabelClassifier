extension ExtractedGrid {

    var observations: [Observation] {
        var observations: [Observation] = []
        for column in columns {
            for row in column.rows {
                observations.append(row.observation)
            }
        }
        return observations
    }
}
