module Pulldown::TagLayoutTemplate::WalkWellsInPools
  def generate_tag_layout(plate, tagged_wells)
    tags   = tag_ids
    groups = group_wells_of_plate(plate)
    pools  = groups.map { |pool| pool.map { |w| w.try(:[], 1) } }.flatten.compact.uniq

    groups.each_with_index do |current_group, group_index|
      if group_index > 0
        prior_group = groups[group_index - 1]

        current_group.each_with_index do |(well,pool_id,emptiness), index|
          break if prior_group.size <= index
          pool_id ||= (index.zero? ? prior_group.last : current_group[index-1])[1]
          prior_pool_id = prior_group[index][1]
          next if (prior_pool_id != pool_id) or prior_pool_id.nil?

          current_group.push([ well, pool_id, emptiness ])
          current_group[index] = [nil, pool_id, true]
        end
      end

      next if current_group.map(&:last).compact.uniq == [ true ] # Are all of the wells "empty"?

      # Remove empty wells from the end of the column, stoping at the first full well.
      current_group = current_group.reverse.drop_while {|well_location,_,emptyness|
        emptyness && well_location.present?
      }.reverse!


      current_group.each_with_index do |(well, pool_id, _), index|
        throw :unacceptable_tag_layout if tags.size <= index
        tagged_wells[well] = [ pools.index(pool_id)+1, tags[index] ] unless well.nil?
      end
    end
  end
end
